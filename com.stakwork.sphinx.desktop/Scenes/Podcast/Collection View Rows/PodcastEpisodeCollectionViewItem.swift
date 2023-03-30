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
        
        //descriptionLabel.stringValue = "Hi Mom"
        
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
    
}


extension NSView {

    func makeCircular() {
     
        layer?.cornerRadius = min(
            frame.size.width,
            frame.size.height
        ) / 2
    }
}
