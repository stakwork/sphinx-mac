//
//  SIgnupButtonView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 10/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol SignupButtonViewDelegate: AnyObject {
    func didClickButton(tag: Int)
}

class SignupButtonView: NSView, LoadableNib {
    
    weak var delegate: SignupButtonViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var backgroundColorBox: NSBox!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var iconLabel: NSTextField!
    @IBOutlet weak var iconImageView: NSImageView!
    @IBOutlet weak var viewButton: CustomButton!
    
    var buttonTag: Int = -1
    
    var backgroundNormalColor = NSColor.Sphinx.PrimaryBlue
    var backgroundHoverColor = NSColor.Sphinx.PrimaryBlueBorder
    var backgroundPressedColor = NSColor.Sphinx.PrimaryBlueHighlighted
    var backgroundDisabledColor = NSColor.Sphinx.PlaceholderText
    var borderNormalColor = NSColor.clear
    var borderHoverColor = NSColor.clear
    var borderHoverWidth: CGFloat = 1.0
    var textNormalColor = NSColor.white
    var textHoverColor = NSColor.white
    var textDisabledColor = NSColor.Sphinx.HeaderBG
    
    var buttonDisabled = false {
        didSet {
            self.backgroundColorBox.fillColor = buttonDisabled ? backgroundDisabledColor : backgroundNormalColor
            self.backgroundColorBox.borderColor = buttonDisabled ? NSColor.clear : borderNormalColor
            self.titleLabel.textColor = buttonDisabled ? textDisabledColor : textNormalColor
            self.iconLabel.textColor = buttonDisabled ? textDisabledColor : textNormalColor
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        viewButton.cursor = .pointingHand
    }
    
    func getButton() -> NSButton {
        return viewButton
    }
    
    func setColors(backgroundNormal: NSColor,
                   backgroundHover: NSColor? = nil,
                   backgroundPressed: NSColor? = nil,
                   borderNormal: NSColor = NSColor.clear,
                   borderHover: NSColor? = nil,
                   borderWidthHover: CGFloat = 1.0,
                   textNormal: NSColor,
                   textHover: NSColor? = nil) {
        
        backgroundNormalColor = backgroundNormal
        backgroundHoverColor = backgroundHover ?? backgroundNormal
        backgroundPressedColor = backgroundPressed ?? backgroundNormal
        textNormalColor = textNormal
        textHoverColor = textHover ?? textNormal
        borderNormalColor = borderNormal
        borderHoverColor = borderHover ?? borderNormal
        borderHoverWidth = borderWidthHover
        
        buttonDisabled = false
    }
    
    func setSignupColors() {
        backgroundDisabledColor = NSColor(hex: "#3B4755")
        textDisabledColor = NSColor(hex: "#141E27")
    }
    
    func configureWith(title: String,
                       icon: String,
                       iconImage: String? = nil,
                       tag: Int,
                       delegate: SignupButtonViewDelegate) {
        
        self.buttonTag = tag
        self.delegate = delegate
        
        titleLabel.stringValue = title
        iconLabel.stringValue = icon
        
        if let iconImage = iconImage {
            iconLabel.stringValue = ""
            iconImageView.image = NSImage(named: iconImage)
            iconImageView.isHidden = false
        }
    }
    
    func setTitle(_ title: String) {
        titleLabel.stringValue = title
    }
    
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea = self.trackingArea {
            self.removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if buttonDisabled { return }
        backgroundColorBox.fillColor = backgroundHoverColor
        backgroundColorBox.borderColor = borderHoverColor
        backgroundColorBox.borderWidth = borderHoverWidth
        titleLabel.textColor = textHoverColor
        iconLabel.textColor = textHoverColor
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if buttonDisabled { return }
        backgroundColorBox.fillColor = backgroundNormalColor
        backgroundColorBox.borderColor = borderNormalColor
        backgroundColorBox.borderWidth = 1.0
        titleLabel.textColor = textNormalColor
        iconLabel.textColor = textNormalColor
    }
    
    @IBAction func buttonClicked(_ sender: NSButton) {
        backgroundColorBox.fillColor = backgroundPressedColor
        delegate?.didClickButton(tag: self.buttonTag)
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: {
            self.backgroundColorBox.fillColor = self.backgroundHoverColor
        })
    }
}
