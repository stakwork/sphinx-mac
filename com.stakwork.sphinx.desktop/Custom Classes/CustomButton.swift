//
//  CustomButton.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 03/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CustomButton : NSButton {
    
    var cursor : NSCursor? = nil
    
    override func resetCursorRects() {
        if let cursor = self.cursor {
            self.addCursorRect(self.bounds, cursor: cursor)
        } else {
            super.resetCursorRects()
        }
    }
}
