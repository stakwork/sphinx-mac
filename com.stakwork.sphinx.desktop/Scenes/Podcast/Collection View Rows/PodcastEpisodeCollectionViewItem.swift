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

class PodcastEpisodeCollectionViewItem: NSCollectionViewItem {

    @IBOutlet weak var playArrow: NSTextField!
    @IBOutlet weak var episodeImageView: NSImageView!
    @IBOutlet weak var episodeNameLabel: NSTextField!
    @IBOutlet weak var divider: NSBox!
    @IBOutlet weak var itemButton: CustomButton!
    @IBOutlet weak var datePublishedLabel: NSTextField!
    @IBOutlet weak var playTimeProgressView: NSView!
    @IBOutlet weak var durationProgressView: NSView!
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
    }
    
    func configureWidth(
        podcast: PodcastFeed?,
        and episode: PodcastEpisode,
        isLastRow: Bool,
        playing: Bool
    ) {
        self.episode = episode
        episodeNameLabel.stringValue = episode.title ?? "No title"
        divider.isHidden = isLastRow
        
        descriptionLabel.stringValue = episode.episodeDescription?.nonHtmlRawString ?? "No description"
        datePublishedLabel.stringValue = episode.dateString ?? ""
        
        let duration = episode.duration ?? 0
        let currentTime = episode.currentTime ?? 0
        
        let timeString = (duration - currentTime).getEpisodeTimeString(
            isOnProgress: currentTime > 0
        )
        
        timeRemainingLabel.stringValue = timeString
        
        durationProgressView.wantsLayer = true
        playTimeProgressView.wantsLayer = true
        durationProgressView.layer?.cornerRadius = 4.0
        playTimeProgressView.layer?.cornerRadius = 4.0
        dotView.wantsLayer = true
        dotView.makeCircular()
        mediaTypeIconImageView.wantsLayer = true
        mediaTypeIconImageView.layer?.cornerRadius = 3.0
        
        downloadIconImage.alphaValue = 0.5
        
        if let currentTime = episode.currentTime,
           let duration = episode.duration{
            let percentage = CGFloat(currentTime)/CGFloat(duration)
            currentTimeProgressWidth.constant = 40.0 * CGFloat(percentage)
            playedCheckmark.isHidden = (percentage > 0.95) ? false : true
            
            self.view.layoutSubtreeIfNeeded()
        }
        else{
            currentTimeProgressWidth.constant = 0.0
            self.view.layoutSubtreeIfNeeded()
        }
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = (playing ? NSColor.Sphinx.ChatListSelected : NSColor.clear).cgColor
        playArrow.isHidden = !playing
        
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
    }
    
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        if let episode = episode{
            self.delegate?.episodeShareTapped(episode: episode)
        }
    }
    
    @IBAction func moreButtonTapped(_ sender: Any){
        print("more tapped")
        showMore()
    }
    func showMore(){
        if let episode = episode{
            let detailVC = PodcastDetailSelectionVC.instantiate(podcast:episode.feed , and: episode)
            WindowsManager.sharedInstance.showNewWindow(with: "podcast.details".localized, size: CGSize(width: 400, height: 600), centeredIn: self.view.window, contentVC: detailVC)
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
