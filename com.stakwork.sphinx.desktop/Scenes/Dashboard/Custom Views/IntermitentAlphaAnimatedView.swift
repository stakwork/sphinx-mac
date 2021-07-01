//
//  IntermitentAlphaAnimatedView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 03/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa


class IntermitentAlphaAnimatedView : NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    var shouldAnimate = false
    
    func configureForRecording() {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.Sphinx.PrimaryRed.cgColor
        self.layer?.cornerRadius = self.frame.size.height / 2
    }
    
    func toggleAnimation(animate: Bool) {
        shouldAnimate = animate
        
        if animate {
            AnimationHelper.animateViewWith(duration: 0.7, animationsBlock: {
                self.alphaValue = 0.65
            }, completion: {
                if self.shouldAnimate {
                    AnimationHelper.animateViewWith(duration: 0.7, animationsBlock: {
                        self.alphaValue = 1.0
                    }, completion: {
                        if self.shouldAnimate {
                            self.toggleAnimation(animate: animate)
                        }
                    })
                }
            })
        }
    }
}
