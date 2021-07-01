//
//  DisabledScrollView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class DisabledScrollView: NSScrollView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func scrollWheel(with event: NSEvent) {
        nextResponder?.scrollWheel(with: event)
    }
}
