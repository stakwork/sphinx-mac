//
//  PodcastEpisodeCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PodcastEpisodeCollectionViewItem: NSCollectionViewItem {

    @IBOutlet weak var playArrow: NSTextField!
    @IBOutlet weak var episodeImageView: NSImageView!
    @IBOutlet weak var episodeNameLabel: NSTextField!
    @IBOutlet weak var divider: NSBox!
    @IBOutlet weak var itemButton: CustomButton!
    
    var episode: OldPodcastEpisode! = nil
    
    public static var podcastImage: NSImage? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemButton.cursor = .pointingHand
    }
    
    func configureWidth(podcast: OldPodcastFeed?, and episode: OldPodcastEpisode, isLastRow: Bool, playing: Bool) {
        self.episode = episode
        
        episodeNameLabel.stringValue = episode.title ?? "No title"
        divider.isHidden = isLastRow
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = (playing ? NSColor.Sphinx.ChatListSelected : NSColor.clear).cgColor
        playArrow.isHidden = !playing
        
        if let img = PodcastEpisodeCollectionViewItem.podcastImage {
            loadEpisodeImage(episode: episode, with: img)
        } else if let image = podcast?.image, let url = URL(string: image) {
            MediaLoader.asyncLoadImage(imageView: episodeImageView, nsUrl: url, placeHolderImage: nil, completion: { img in
                PodcastEpisodeCollectionViewItem.podcastImage = img
                self.loadEpisodeImage(episode: episode, with: img)
            }, errorCompletion: { _ in
                self.loadEpisodeImage(episode: episode, with: NSImage(named: "profileAvatar")!)
            })
        }
    }
    
    func loadEpisodeImage(episode: OldPodcastEpisode, with defaultImg: NSImage) {
        if let image = episode.image, let url = URL(string: image) {
            MediaLoader.asyncLoadImage(imageView: episodeImageView, nsUrl: url, placeHolderImage: nil, id: episode.id ?? -1, completion: { (img, id) in
                if self.isDifferentEpisode(episodeId: id) { return }
                self.episodeImageView.image = img
            }, errorCompletion: { _ in
                self.episodeImageView.image = defaultImg
            })
        } else {
            self.episodeImageView.image = defaultImg
        }
    }
    
    func isDifferentEpisode(episodeId: Int) -> Bool {
        return episodeId != self.episode.id
    }
}
