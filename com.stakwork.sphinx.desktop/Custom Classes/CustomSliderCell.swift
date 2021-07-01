//
//  CustomSliderCell.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CustomSliderCell: NSSliderCell {

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func drawBar(inside aRect: NSRect, flipped: Bool) {
        var rect = aRect
        rect.size.height = CGFloat(5)
        let barRadius = CGFloat(2.5)
        let value = CGFloat((self.doubleValue - self.minValue) / (self.maxValue - self.minValue))
        let finalWidth = CGFloat(value * (self.controlView!.frame.size.width - 8))
        var leftRect = rect
        leftRect.size.width = finalWidth
        let bg = NSBezierPath(roundedRect: rect, xRadius: barRadius, yRadius: barRadius)
        NSColor.Sphinx.SecondaryText.setFill()
        bg.fill()
        let active = NSBezierPath(roundedRect: leftRect, xRadius: barRadius, yRadius: barRadius)
        NSColor.Sphinx.PrimaryGreen.setFill()
        active.fill()
    }

}
