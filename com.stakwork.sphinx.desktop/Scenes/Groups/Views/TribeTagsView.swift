//
//  TribeTagsView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/10/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa

class TribeTagsView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    override func mouseDown(with event: NSEvent) {
        self.isHidden = true
        return
    }
    
    override func mouseDragged(with event: NSEvent) {
        return
    }
    
    override func mouseUp(with event: NSEvent) {
        return
    }
    
    override func scrollWheel(with event: NSEvent) {
        return
    }
    
}
