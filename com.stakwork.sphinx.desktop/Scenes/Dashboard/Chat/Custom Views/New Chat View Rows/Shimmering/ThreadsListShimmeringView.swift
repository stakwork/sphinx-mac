//
//  ThreadsListShimmeringView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ThreadsListShimmeringView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
    }
    
    func startAnimating() {
        self.isHidden = false
        
        if !self.isHidden {
            AnimationHelper.animateViewWith(duration: 0.2, animationsBlock: {
                self.alphaValue = 0.05
            }, completion: {
                if !self.isHidden {
                    AnimationHelper.animateViewWith(duration: 0.2, animationsBlock: {
                        self.alphaValue = 0.25
                    }, completion: {
                        if !self.isHidden {
                            self.startAnimating()
                        }
                    })
                }
            })
        }
    }
    
    func toggle(show: Bool) {
        if show {
            self.isHidden = false
            self.alphaValue = 0.15
            self.startAnimating()
        } else {
            self.isHidden = true
        }
    }
    
}
