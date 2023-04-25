//
//  PodcastEpisodeCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol PodcastEpisodeCollectionViewItemDelegate{
    func episodeShareTapped(episode:PodcastEpisode)
}

class PodcastEpisodeCollectionViewItem: NSCollectionViewItem, PodcastDetailSelectionVCDelegate {

    @IBOutlet weak var playArrowBack: NSBox!
    @IBOutlet weak var playArrow: NSTextField!
    @IBOutlet weak var episodeImageView: NSImageView!
    @IBOutlet weak var episodeNameLabel: NSTextField!
    @IBOutlet weak var divider: NSBox!
    @IBOutlet weak var itemButton: CustomButton!
    @IBOutlet weak var datePublishedLabel: NSTextField!
    @IBOutlet weak var playTimeProgressView: NSView!
    @IBOutlet weak var playTimeProgressViewBox: NSBox!
    @IBOutlet weak var durationProgressView: NSView!
    @IBOutlet weak var durationViewBox: NSBox!
    @IBOutlet weak var playedCheckmark: NSImageView!
    @IBOutlet weak var dotView: NSView!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var timeRemainingLabel: NSTextField!
    @IBOutlet weak var shareButton: NSImageView!
    @IBOutlet weak var mediaTypeIconImageView: NSImageView!
    @IBOutlet weak var downloadIconImage:NSImageView!
    
    
    @IBOutlet weak var currentTimeProgressWidth : NSLayoutConstraint!
    
    var episode:PodcastEpisode? = nil
    var delegate:PodcastEpisodeCollectionViewItemDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemButton.cursor = .pointingHand
        
        durationProgressView.wantsLayer = true
        playTimeProgressView.wantsLayer = true
        durationProgressView.layer?.cornerRadius = 2.0
        playTimeProgressView.layer?.cornerRadius = 2.0
        
        dotView.wantsLayer = true
        dotView.makeCircular()
        
        mediaTypeIconImageView.wantsLayer = true
        mediaTypeIconImageView.layer?.cornerRadius = 3.0
        
        episodeImageView.wantsLayer = true
        episodeImageView.layer?.cornerRadius = 6.0
        
        downloadIconImage.alphaValue = 0.5
    }
    
    func configureWith(
        podcast: PodcastFeed?,
        and episode: PodcastEpisode,
        isLastRow: Bool,
        playing: Bool
    ) {
        self.episode = episode
        
        episodeNameLabel.stringValue = episode.title ?? "No title"
        episodeNameLabel.maximumNumberOfLines = 2
        
        descriptionLabel.stringValue = episode.episodeDescription?.nonHtmlRawString ?? "No description"
        descriptionLabel.maximumNumberOfLines = 2
        
        datePublishedLabel.stringValue = episode.dateString ?? ""
        
        playArrow.stringValue = playing ? "pause" : "play_arrow"
        durationProgressView.alphaValue = 0.1
        playTimeProgressViewBox.fillColor = playing ? NSColor.Sphinx.BlueTextAccent : NSColor.Sphinx.Text
        playTimeProgressView.alphaValue = playing ? 1.0 : 0.3
        
        episodeImageView.sd_cancelCurrentImageLoad()
        
        let imageUrl = episode.imageURLPath ?? podcast?.imageURLPath
        
        if let episodeURLPath = imageUrl, let url = URL(string: episodeURLPath) {
            episodeImageView.sd_setImage(
                with: url,
                placeholderImage: NSImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        }
        
        divider.isHidden = isLastRow
        
        let duration = episode.duration ?? 0
        let currentTime = episode.currentTime ?? 0
        
        let timeString = (duration - currentTime).getEpisodeTimeString(
            isOnProgress: currentTime > 0
        )
        
        let shouldShowProgressView = (duration > 0 && currentTime > 0)
        durationProgressView.isHidden = !shouldShowProgressView
        playTimeProgressView.isHidden = !shouldShowProgressView
        
        if let currentTime = episode.currentTime, let duration = episode.duration {
            
            let percentage = max(CGFloat(currentTime)/CGFloat(duration), CGFloat(0.075))
            currentTimeProgressWidth.constant = 40.0 * CGFloat(percentage)
            playTimeProgressViewBox.layoutSubtreeIfNeeded()
            
            playedCheckmark.isHidden = !episode.wasPlayed
            timeRemainingLabel.stringValue = episode.wasPlayed ? "Played" : timeString
        } else {
            timeRemainingLabel.stringValue = timeString
            playedCheckmark.isHidden = true
            
            currentTimeProgressWidth.constant = 0.0
            playTimeProgressViewBox.layoutSubtreeIfNeeded()
        }
    }
    
    func toggleWasPlayed(){
        self.episode?.wasPlayed = (!(self.episode?.wasPlayed ?? true))
        shouldReloadList()
    }
    
    func shouldReloadList() {
        self.collectionView?.reloadData()
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        if let episode = episode {
            self.delegate?.episodeShareTapped(episode: episode)
        }
    }
    
    @IBAction func moreButtonTapped(_ sender: Any){
        showMore()
    }
    
    func showMore(){
        if let episode = episode {
            
            let detailVC = PodcastDetailSelectionVC.instantiate(
                podcast: episode.feed,
                and: episode,
                delegate: self
            )
            
            WindowsManager.sharedInstance.showNewWindow(
                with: "podcast.details".localized,
                size: CGSize(width: 400, height: 600),
                centeredIn: self.view.window,
                contentVC: detailVC
            )
        }
    }
    
}


extension NSView {

    func makeCircular() {
     
        layer?.cornerRadius = min(
            frame.size.width,
            frame.size.height
        ) / 2
    }
}


extension Int{
    func getEpisodeTimeString(
        isOnProgress: Bool
    ) -> String {
        let hours = Int((self % 86400) / 3600)
        let minutes = Int((self % 3600) / 60)
        
        if (self == 0) {
            return ""
        }
        
        var string = ""
        
        if hours > 1 {
            string += "\(hours) hrs"
        } else if hours > 0 {
            string += "\(hours) hr"
        }
        
        string += " \(minutes) min"
        
        if isOnProgress {
            string += " left"
        }
        
        return string
    }
}
