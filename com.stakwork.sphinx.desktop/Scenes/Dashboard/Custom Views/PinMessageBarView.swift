//
//  PinMessageBarView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 24/05/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class PinMessageBarView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var messageLabel: NSTextField!
    
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
    
}
