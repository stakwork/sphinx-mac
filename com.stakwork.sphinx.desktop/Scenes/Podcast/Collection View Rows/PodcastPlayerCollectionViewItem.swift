//
//  PodcastPlayerCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

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
    var playerHelper: PodcastPlayerHelper! = nil
    var chat: Chat! = nil
    
    var livePodcastDataSource: PodcastLiveDataSource? = nil
    var liveMessages: [Int: [TransactionMessage]] = [:]
    
    var wasPlayingOnDrag = false
    
    let kDurationLineMargins: CGFloat = 64
    
    let speedValues = ["0.5x", "0.8x", "1x", "1.2x", "1.5x", "2.1x"]
    
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
        
        boostButtonView.delegate = self
    }
    
    func configureWith(playerHelper: PodcastPlayerHelper, chat: Chat, delegate: PodcastPlayerViewDelegate) {
        self.delegate = delegate
        self.chat = chat
        self.playerHelper = playerHelper
        self.playerHelper.delegate = self
        self.setup()
        
        podcastSatsView.configureWith(chat: chat)
        preparePlayer()
    }
    
    private func setup() {
        showInfo()
        configureControls()
        configureSpeedButton()
        
        mouseDraggableView.delegate = self
    }
    
    func addMessagesFor(ts: Int) {
        if !playerHelper.isPlaying() {
            return
        }
        
        if let liveM = liveMessages[ts] {
            livePodcastDataSource?.insert(messages: liveM)
        }
    }
    
    func showInfo() {
        let imageURL = playerHelper.getImageURL()
        loadImage(imageURL: imageURL)
        episodeLabel.stringValue = playerHelper.getCurrentEpisode()?.title ?? ""
        playerHelper.loadInitialTime()
        
        loadMessages()
    }
    
    func loadMessages() {
        liveMessages = [:]
        
        let episodeId = playerHelper.getCurrentEpisode()?.id ?? -1
        let messages = TransactionMessage.getLiveMessagesFor(chat: chat, episodeId: episodeId)
        
        for m in messages {
            addToLiveMessages(message: m)
        }
        
        if livePodcastDataSource == nil {
            livePodcastDataSource = PodcastLiveDataSource(collectionView: liveCollectionView, scrollView: liveScrollView, chat: chat)
        }
        livePodcastDataSource?.resetData()
    }
    
    func addToLiveMessages(message: TransactionMessage) {
        if let ts = message.getTimeStamp() {
            var existingM = liveMessages[ts] ?? Array<TransactionMessage>()
            existingM.append(message)
            liveMessages[ts] = existingM
        }
    }
    
    func configureSpeedButton() {
        let selectedValue = playerHelper.playerSpeed.speedDescription + "x"
        
        speedButton.removeAllItems()
        speedButton.addItems(withTitles: speedValues)
        
        let selectedIndex = speedValues.firstIndex(of: selectedValue)
        speedButton.selectItem(at: selectedIndex ?? 2)
    }
    
    func loadImage(imageURL: URL?) {
        guard let imageURL = imageURL else {
            self.episodeImageView.image = NSImage(named: "profileAvatar")!
            return
        }
        
        MediaLoader.asyncLoadImage(imageView: episodeImageView, nsUrl: imageURL, placeHolderImage: nil, completion: { img in
            self.episodeImageView.image = img
        }, errorCompletion: { _ in
            self.episodeImageView.image = NSImage(named: "profileAvatar")!
        })
    }
    
    func preparePlayer() {
        playerHelper.preparePlayer(completion: {
            self.onEpisodePlayed()
        })
    }
    
    func onEpisodePlayed() {
        playerHelper?.updateCurrentTime()
        configureControls()
    }
    
    func configureControls() {
        let isPlaying = playerHelper.isPlaying()
        playPauseButton.title = isPlaying ? "pause" : "play_arrow"
    }
    
    func setLabels(duration: Int, currentTime: Int) {
        let (ctHours, ctMinutes, ctSeconds) = currentTime.getTimeElements()
        let (dHours, dMinutes, dSeconds) = duration.getTimeElements()
        currentTimeLabel.stringValue = "\(ctHours):\(ctMinutes):\(ctSeconds)"
        durationLabel.stringValue = "\(dHours):\(dMinutes):\(dSeconds)"
        
        let progress = (Double(currentTime) * 100 / Double(duration))/100
        let durationLineWidth = self.view.frame.width - kDurationLineMargins
        var progressWidth = durationLineWidth * CGFloat(progress)
        
        if !progressWidth.isFinite || progressWidth < 0 {
            progressWidth = 0
        }
        
        progressLineWidth.constant = progressWidth
        progressLine.layoutSubtreeIfNeeded()
    }
    
    func updateProgressLineAndLabel(gestureXLocation: CGFloat) {
        let totalProgressWidth = CGFloat(durationLine.frame.size.width)
        let translation = (gestureXLocation < 0) ? 0 : ((gestureXLocation > totalProgressWidth) ? totalProgressWidth : gestureXLocation)
        
        if !translation.isFinite || translation < 0 {
            return
        }
        
        progressLineWidth.constant = translation
        progressLine.layoutSubtreeIfNeeded()
        
        let progress = ((progressLineWidth.constant * 100) / durationLine.frame.size.width) / 100
        playerHelper.shouldUpdateTimeLabels(progress: Double(progress))
    }
    
    func togglePlayState() {
        playerHelper.togglePlayState()
        configureControls()
        delegate?.shouldReloadEpisodesTable()
    }
    
    @IBAction func controlButtonTouched(_ sender: NSButton) {
        switch(sender.tag) {
        case ControlButtons.ShareClip.rawValue:
            let comment = playerHelper.getPodcastComment()
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
        livePodcastDataSource?.resetData()
        playerHelper.seekTo(seconds: seconds)
    }
    
    @IBAction func speedValueChanged(_ sender: Any) {
        if let speedButton = sender as? NSPopUpButton {
            let speed = speedValues[speedButton.indexOfSelectedItem].replacingOccurrences(of: "x", with: "")
            playerHelper.changeSpeedTo(value: Float(speed) ?? 1)
        }
    }
}

extension PodcastPlayerCollectionViewItem : MouseDraggableViewDelegate {
    func mouseDownOn(x: CGFloat) {
        livePodcastDataSource?.resetData()
        wasPlayingOnDrag = playerHelper.isPlaying()
        playerHelper.shouldPause()
        
        mouseDraggedOn(x: x)
    }
    
    func mouseUpOn(x: CGFloat) {
        let progress = ((progressLineWidth.constant * 100) / durationLine.frame.size.width) / 100
        playerHelper.seekTo(progress: Double(progress), play: wasPlayingOnDrag)
        wasPlayingOnDrag = false
        
        delegate?.shouldSyncPodcast()
    }
    
    func mouseDraggedOn(x: CGFloat) {
        let totalProgressWidth = CGFloat(durationLine.frame.size.width)
        let translation = (x < 0) ? 0 : ((x > totalProgressWidth) ? totalProgressWidth : x)
        
        if !translation.isFinite || translation < 0 {
            return
        }

        progressLineWidth.constant = translation
        progressLine.layoutSubtreeIfNeeded()
        
        let progress = ((progressLineWidth.constant * 100) / durationLine.frame.size.width) / 100
        
        playerHelper.shouldUpdateTimeLabels(progress: Double(progress))
    }
}

extension PodcastPlayerCollectionViewItem : PodcastPlayerDelegate {
    func didTapEpisodeAt(index: Int) {
        playerHelper.prepareEpisode(index: index, autoPlay: true, resetTime: true, completion: {
            self.configureControls()
            self.delegate?.shouldReloadEpisodesTable()
        })
        delegate?.shouldReloadEpisodesTable()
        showInfo()
    }
    
    func shouldUpdateLabels(duration: Int, currentTime: Int) {
        setLabels(duration: duration, currentTime: currentTime)
    }
    
    func shouldToggleLoadingWheel(loading: Bool) {
        audioLoading = loading
    }
    
    func shouldUpdatePlayButton() {
        configureControls()
    }
    
    func shouldUpdateEpisodeInfo() {
        showInfo()
        delegate?.shouldReloadEpisodesTable()
    }
    
    func shouldInsertMessagesFor(currentTime: Int) {
        addMessagesFor(ts: currentTime)
    }
}

extension PodcastPlayerCollectionViewItem : BoostButtonViewDelegate {
    func didTouchButton() {
        let amount: Int = UserDefaults.Keys.tipAmount.get(defaultValue: 100)
        
        if let boostMessage = playerHelper.getBoostMessage(amount: amount) {
            playerHelper.processPayment(amount: amount)
            
            if let message = delegate?.shouldSendBoost(message: boostMessage, amount: amount, animation: false) {
                addToLiveMessages(message: message)
                livePodcastDataSource?.insert(messages: [message])
            }
        }
    }
}
