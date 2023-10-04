//
//  PodcastBoostView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 13/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class PodcastBoostView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var boostIconView: NSBox!
    
    static let kViewHeight: CGFloat = 52

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setup()
    }
    
    func setup() {
        boostIconView.wantsLayer = true
        boostIconView.layer?.cornerRadius = boostIconView.bounds.height / 2
    }
    
    func configureWith(
        podcastBoost: BubbleMessageLayoutState.PodcastBoost
    ) {
        amountLabel.stringValue = podcastBoost.amount.formattedWithSeparator
    }
    
}
