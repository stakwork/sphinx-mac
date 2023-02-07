//
//  NewEpisodeAlertView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 16/03/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NewEpisodeAlertView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var backgroundColorBox: NSBox!
    @IBOutlet weak var bubbleBox: NSBox!
    @IBOutlet weak var arrowView: NSView!
    @IBOutlet weak var imageView: AspectFillNSImageView!
    @IBOutlet weak var episodeTitleLabel: NSTextField!
    
    var episode: PodcastEpisode! = nil
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
    }
    
    override func mouseDown(with event: NSEvent) {
        hideView()
        return super.mouseDown(with: event)
    }
    
    func hideView() {
        animateView(show: false, delay: 0.0, completion: {
            self.removeFromSuperview()
        })
    }
    
    static func checkForNewEpisode(podcast: PodcastFeed, view: NSView) -> NewEpisodeAlertView? {
        if podcast.episodesArray.isEmpty {
            return nil
        }

        let lastStoredEpisodeId = podcast.lastEpisodeId ?? ""
        let lastEpisode = podcast.episodesArray[0]
        let lastEpisodeId = lastEpisode.itemID

        podcast.lastEpisodeId = lastEpisodeId

        if !lastStoredEpisodeId.isEmpty && lastStoredEpisodeId != lastEpisodeId {
            
            let newEpisodeView = NewEpisodeAlertView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
            newEpisodeView.episode = lastEpisode
            newEpisodeView.configureView()
            view.addSubview(newEpisodeView)
            
            return newEpisodeView
        }
        return nil
    }
    
    func configureView() {
        backgroundColorBox.alphaValue = 0.0
        arrowView.addDownTriangle(color: NSColor.Sphinx.BodyInverted)
        
        configureEpisode()
        animateView(show: true, delay: 0.2, completion: {})
    }
    
    func animateView(show: Bool, delay: Double, completion: @escaping () -> ()) {
        DelayPerformedHelper.performAfterDelay(seconds: delay, completion: {
            AnimationHelper.animateViewWith(duration: 0.2, animationsBlock: {
                self.backgroundColorBox.alphaValue = show ? 1.0 : 0.0
            }, completion: {
                completion()
            })
        })
    }
    
    func configureEpisode() {
        episodeTitleLabel.stringValue = episode.title ?? "title.not.available"
        episodeTitleLabel.layoutSubtreeIfNeeded()
        
        if episodeTitleLabel.frame.height > 20 {
            episodeTitleLabel.font = NSFont(name: "Roboto-Medium", size: 14.0)!
        }
        
        if let image = episode.imageURLPath, let url = URL(string: image) {
            imageView.sd_setImage(
                with: url,
                placeholderImage: NSImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        }
    }
}
