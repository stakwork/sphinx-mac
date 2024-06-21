//
//  AspectFillNSImageView.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 12/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class AspectFillNSImageView: NSImageView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let currentImage = self.image
        self.image = currentImage
    }
    
    @IBInspectable
    var rounded: Bool = false
    
    @IBInspectable
    var radius: CGFloat = 0
    
    var gravity: CALayerContentsGravity = CALayerContentsGravity.resizeAspectFill
    
    var bordered: Bool = false
    var borderColor = NSColor(red: 203/255, green: 206/255, blue: 213/255, alpha: 1).cgColor
    
    var imageName: String = ""
    
    func customizeLayer() {
        self.wantsLayer = true
        
        if rounded {
            if self.radius > 0 {
                self.layer?.cornerRadius = self.radius
            } else {
                self.layer?.cornerRadius = self.frame.height / 2
            }
        }
        
        if bordered {
            self.layer?.borderWidth = 1
            self.layer?.borderColor = self.borderColor
        } else {
            self.layer?.borderWidth = 0
        }
        
        self.layer?.contentsGravity = gravity
    }
    
    open override var image: NSImage? {
        set {
            self.layer = CALayer()
            self.customizeLayer()
            self.layer?.contents = newValue
            super.image = newValue
        }

        get {
            return super.image
        }
    }
    
    open var imageWithName: String {
        set {
            let image = NSImage(named: newValue)
            self.layer = CALayer()
            self.customizeLayer()
            self.layer?.contents = image
            super.image = image
            self.imageName = newValue
        }

        get {
            return self.imageName
        }
    }
    
}
