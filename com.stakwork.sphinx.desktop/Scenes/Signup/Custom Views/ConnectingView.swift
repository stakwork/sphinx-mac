//
//  ConnectingView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 10/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ConnectingView: NSView, LoadableNib {
    
    weak var delegate: WelcomeEmptyViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var connectingImageView: NSImageView!
    @IBOutlet weak var connectingLabel: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    init(frame frameRect: NSRect, delegate: WelcomeEmptyViewDelegate) {
        super.init(frame: frameRect)
        loadViewFromNib()
        self.delegate = delegate
    }
}
