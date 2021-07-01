//
//  NSWindow.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 13/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension NSWindow {
    
    func replaceContentBy(vc: NSViewController, with size: CGSize? = nil) {
        if let size = size {
            let x = self.frame.origin.x + ((self.frame.width - size.width) / 2)
            let y = self.frame.origin.y + ((self.frame.height - size.height) / 2)
            self.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
        }
        if let frame = self.contentView?.frame {
            vc.view.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        }
        self.contentViewController = vc
    }
    
}
