//
//  PodcastDetailSelectionVC.swift
//  Sphinx
//
//  Created by James Carucci on 3/31/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import Cocoa

class PodcastDetailSelectionVC : NSViewController{
    
    @IBOutlet weak var podcastDetailImageView: NSImageView!
    @IBOutlet weak var podcastTitleLabel: NSTextField!
    @IBOutlet weak var episodeTitleLabel: NSTextField!
    
    override func viewDidLoad() {
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.Sphinx.BlueTextAccent.cgColor
        
        episodeTitleLabel.maximumNumberOfLines = 3
    }
    
    static func instantiate() -> PodcastDetailSelectionVC {
        let viewController = StoryboardScene.Podcast.podcastDetailSelectionViewController.instantiate()
        
        return viewController
    }
}
