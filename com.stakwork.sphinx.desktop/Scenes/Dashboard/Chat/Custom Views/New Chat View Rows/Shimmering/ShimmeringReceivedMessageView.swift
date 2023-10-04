//
//  ShimmeringReceivedMessageView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 21/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ShimmeringReceivedMessageView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!

    @IBOutlet weak var circularBox: NSBox!
    @IBOutlet weak var bubbleBox: NSBox!
    @IBOutlet weak var arrowView: NSView!
    
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
        arrowView.drawReceivedBubbleArrow(color: NSColor.Sphinx.SecondaryText)
    }
}
