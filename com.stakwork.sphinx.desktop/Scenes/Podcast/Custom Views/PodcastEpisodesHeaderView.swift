//
//  PodcastEpisodesHeaderView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PodcastEpisodesHeaderView: NSView {
    
    @IBOutlet weak var episodesLabel: NSTextField!
    @IBOutlet weak var episodesCountLabel: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configureWith(count: Int) {
        episodesLabel.stringValue = "episodes".localized.uppercased()
        episodesCountLabel.stringValue = "\(count)"
    }
}
