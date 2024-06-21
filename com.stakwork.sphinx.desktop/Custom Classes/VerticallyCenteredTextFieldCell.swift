//
//  VerticallyCenteredTextFieldCell.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class VerticallyCenteredTextFieldCell: NSTextFieldCell {
//    override func drawingRect(forBounds rect: NSRect) -> NSRect {
//        let newRect = NSRect(x: 0, y: (rect.size.height - 22) / 2, width: rect.size.width, height: 22)
//        return super.drawingRect(forBounds: newRect)
//    }
}

class VerticallyCenteredSecureTextFieldCell: NSSecureTextFieldCell {
//    override func drawingRect(forBounds rect: NSRect) -> NSRect {
//        let newRect = NSRect(x: 0, y: (rect.size.height - 22) / 2, width: rect.size.width, height: 22)
//        return super.drawingRect(forBounds: newRect)
//    }
}

class VerticallyCenteredButtonCell : NSButtonCell {
//    override func titleRect(forBounds rect: NSRect) -> NSRect {
//        var theRect = super.titleRect(forBounds: rect)
//        let topMargin = round(theRect.size.height * 0.05)
//        theRect.origin.y = rect.origin.y+rect.size.height-(theRect.size.height+(theRect.origin.y-rect.origin.y))-topMargin
//        return theRect
//    }
}
