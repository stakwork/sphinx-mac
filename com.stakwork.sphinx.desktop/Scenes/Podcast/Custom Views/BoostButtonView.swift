//
//  BoostButtonView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol BoostButtonViewDelegate : AnyObject {
    func didTouchButton()
}

class BoostButtonView: NSView, LoadableNib {
    
    weak var delegate: BoostButtonViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var greenCircle: NSBox!
    @IBOutlet weak var boostIcon: NSImageView!
    @IBOutlet weak var boostButton: CustomButton!
    @IBOutlet weak var greenCircleWidth: NSLayoutConstraint!
    @IBOutlet weak var boostIconWidth: NSLayoutConstraint!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    @IBAction func boostButtonClicked(_ sender: Any) {
        animateButton()
        delegate?.didTouchButton()
    }
    
    func animateButton() {
        boostButton.isEnabled = false
        boostButton.cursor = .pointingHand
        
        greenCircleWidth.constant = 36
        greenCircle.layer?.cornerRadius = 18
        greenCircle.layoutSubtreeIfNeeded()
        
        AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
            self.greenCircle.alphaValue = 0
            self.boostIconWidth.constant = 50
            self.boostIcon.layoutSubtreeIfNeeded()
        }, completion: {
            AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
                self.greenCircle.alphaValue = 1
                self.greenCircleWidth.constant = 28
                self.greenCircle.layer?.cornerRadius = 14
                self.boostIconWidth.constant = 22
                self.layoutSubtreeIfNeeded()
            }, completion: {
                DispatchQueue.main.async {
                    self.boostButton.isEnabled = true
                }
            })
        })
    }
}

