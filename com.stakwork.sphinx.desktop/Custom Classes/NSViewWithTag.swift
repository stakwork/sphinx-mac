//
//  NSViewWithTag.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 13/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class NSViewWithTag: NSView {
    
    @IBInspectable
    var viewTag: Int = -1

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
}
