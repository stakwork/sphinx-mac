//
//  RounderBottomView.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 14/06/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

class RoundedBottomCornersView: NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Define the radius for the bottom corners
        let radius: CGFloat = 20.0
        let path = NSBezierPath()
        
        // Start at the top left corner
        path.move(to: NSPoint(x: bounds.minX, y: bounds.maxY))
        
        // Draw top line
        path.line(to: NSPoint(x: bounds.maxX, y: bounds.maxY))
        
        // Draw right side
        path.line(to: NSPoint(x: bounds.maxX, y: bounds.minY + radius))
        
        // Draw bottom right corner curve
        path.curve(to: NSPoint(x: bounds.maxX - radius, y: bounds.minY),
                   controlPoint1: NSPoint(x: bounds.maxX, y: bounds.minY),
                   controlPoint2: NSPoint(x: bounds.maxX, y: bounds.minY))
        
        // Draw bottom line
        path.line(to: NSPoint(x: bounds.minX + radius, y: bounds.minY))
        
        // Draw bottom left corner curve
        path.curve(to: NSPoint(x: bounds.minX, y: bounds.minY + radius),
                   controlPoint1: NSPoint(x: bounds.minX, y: bounds.minY),
                   controlPoint2: NSPoint(x: bounds.minX, y: bounds.minY))
        
        // Draw left side
        path.line(to: NSPoint(x: bounds.minX, y: bounds.maxY))
        
        // Close the path
        path.close()
        
        // Set the fill color
        NSColor.clear.setFill()
//        NSColor.Sphinx.HeaderBG.setFill()
        path.fill()
    }
}
