//
//  PodcastPlayerCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import AVKit

protocol PodcastPlayerViewDelegate : AnyObject {
    func shouldReloadEpisodesTable()
    func shouldShareClip(comment: PodcastComment)
    func shouldSendBoost(message: String, amount: Int, animation: Bool) -> TransactionMessage?
    func shouldSyncPodcast()
}

class PodcastPlayerCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var episodeImageView: NSImageView!
    @IBOutlet weak var episodeLabel: NSTextField!
    @IBOutlet weak var currentTimeLabel: NSTextField!
    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet weak var durationLine: NSBox!
    @IBOutlet weak var progressLine: NSBox!
    @IBOutlet weak var currentTimeDot: NSBox!
    @IBOutlet weak var playPauseButton: CustomButton!
    @IBOutlet weak var progressLineWidth: NSLayoutConstraint!
    @IBOutlet weak var mouseDraggableView: MouseDraggableView!
    @IBOutlet weak var podcastSatsView: PodcastSatsView!
    @IBOutlet weak var speedButton: NSPopUpButton!
    @IBOutlet weak var liveScrollView: DisabledScrollView!
    @IBOutlet weak var liveCollectionView: NSCollectionView!
    @IBOutlet weak var boostButtonView: BoostButtonView!
    @IBOutlet weak var audioLoadingWheel: NSProgressIndicator!
    
    weak var delegate: PodcastPlayerViewDelegate?
    
    let podcastPlayerController = PodcastPlayerController.sharedInstance
    let feedBoostHelper = FeedBoostHelper()
    
//    var livePodcastDataSource: PodcastLiveDataSource? = nil
    var liveMessages: [Int: [TransactionMessage]] = [:]
    
    let kDurationLineMargins: CGFloat = 64
    
    let speedValues = ["0.5x", "0.8x", "1x", "1.2x", "1.5x", "2.1x"]
    
    var chat: Chat! = nil
    var podcast: PodcastFeed! = nil
    
    var dragging = false
    
    var audioLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: audioLoading, loadingWheel: audioLoadingWheel, color: NSColor.Sphinx.Text, controls: [])
        }
    }
    
    public enum ControlButtons: Int {
        case ShareClip
        case Replay15
        case Forward30
        case PlayPause
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        DispatchQueue.main.async {
            self.episodeImageView.wantsLayer = true
            self.episodeImageView.imageScaling = .scaleProportionallyUpOrDown
        }
        */
        boostButtonView.delegate = self
    }
    
    func configureWith(
        chat: Chat,
        podcast: PodcastFeed,
        delegate: PodcastPlayerViewDelegate
    ) {
        self.chat = chat
        self.podcast = podcast
        self.delegate = delegate
        
        feedBoostHelper.configure(with: podcast.feedID, and: chat)
        
        podcastPlayerController.addDelegate(self, withKey: PodcastDelegateKeys.PodcastPlayerView.rawValue)
        
        setupView()
    }
    
    func togglePlayState() {
        guard let podcastData = podcast.getPodcastData() else {
            return
        }
        
        if podcastPlayerController.isPlaying(podcastId: podcastData.podcastId) {
            podcastPlayerController.submitAction(
                UserAction.Pause(podcastData)
            )
        } else {
            podcastPlayerController.submitAction(
                UserAction.Play(podcastData)
            )
        }
        delegate?.shouldReloadEpisodesTable()
    }
    
    @IBAction func controlButtonTouched(_ sender: NSButton) {
        switch(sender.tag) {
        case ControlButtons.ShareClip.rawValue:
            let comment = podcast.getPodcastComment()
            delegate?.shouldShareClip(comment: comment)
            break
        case ControlButtons.Replay15.rawValue:
            seekTo(seconds: -15)
            break
        case ControlButtons.Forward30.rawValue:
            seekTo(seconds: 30)
            break
        case ControlButtons.PlayPause.rawValue:
            togglePlayState()
            break
        default:
            break
        }
    }
    
    func seekTo(seconds: Double) {
//        livePodcastDataSource?.resetData()
        
        var newTime = podcast.currentTime + Int(seconds)
        newTime = max(newTime, 0)
        newTime = min(newTime, podcast.duration)
        
        guard let podcastData = podcast.getPodcastData(
            currentTime: newTime
        ) else {
            return
        }
        
        setProgress(
            duration: podcastData.duration ?? 0,
            currentTime: newTime
        )
        
        podcastPlayerController.submitAction(
            UserAction.Seek(podcastData)
        )
    }
    
    func didTapShareEpisode(index:Int)->String?{
        guard let episode = podcast.getEpisodeWith(index: index) else {
            return nil
        }
        return episode.constructShareLink()
    }
    
    func didTapEpisodeAt(index: Int) {
        audioLoading = true
        
        guard let episode = podcast.getEpisodeWith(index: index) else {
            return
        }
        selectEpisode(episode: episode)
    }
    
    func selectEpisode(episode:PodcastEpisode, atTime:Int?=nil){
        guard let podcastData = podcast.getPodcastData(
            episodeId: episode.itemID
        ) else {
            return
        }
            
        podcastPlayerController.submitAction(
            UserAction.TogglePlay(podcastData)
        )
        
        if let time = atTime{
            setProgress(
                duration: podcastData.duration ?? 0,
                currentTime: time
            )
        }
        
        delegate?.shouldReloadEpisodesTable()
    }
    
    @IBAction func speedValueChanged(_ sender: Any) {
        if let speedButton = sender as? NSPopUpButton {
            let speedString = speedValues[speedButton.indexOfSelectedItem].replacingOccurrences(of: "x", with: "")
            let newSpeed = Float(speedString) ?? 1

            guard let podcastData = podcast.getPodcastData(
                playerSpeed: newSpeed
            ) else {
                return
            }
            
            podcastPlayerController.submitAction(
                UserAction.AdjustSpeed(podcastData)
            )
            
            configureControls()
            
            delegate?.shouldSyncPodcast()
        }
    }
}
