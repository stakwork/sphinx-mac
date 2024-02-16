//
//  MessageOptionView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 16/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol MessageOptionViewDelegate: AnyObject {
    func didTapButton(tag: Int)
}

class MessageOptionView: NSView, LoadableNib {
    
    weak var delegate: MessageOptionViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var iconLabel: NSTextField!
    @IBOutlet weak var iconImageView: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var separator: NSBox!
    @IBOutlet weak var optionButton: CustomButton!
    @IBOutlet weak var labelLeadingConstraint: NSLayoutConstraint!
    
    var buttonTag: Int = -1
    
    struct Option {
        var icon: String? = nil
        var iconImage: String? = nil
        var title: String
        var tag: Int
        var color: NSColor
        var showLine: Bool
        
        init(icon: String?,
             iconImage: String?,
             title: String,
             tag: Int,
             color: NSColor,
             showLine: Bool) {
            
            self.icon = icon
            self.iconImage = iconImage
            self.title = title
            self.tag = tag
            self.color = color
            self.showLine = showLine
        }
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

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        self.wantsLayer = true
        optionButton.cursor = .pointingHand
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        self.layer?.backgroundColor = NSColor.Sphinx.Text.withAlphaComponent(0.1).cgColor
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
    }
    
    func configure(option: Option, delegate: MessageOptionViewDelegate) {
        self.delegate = delegate
        self.buttonTag = option.tag
        
        iconLabel.textColor = option.color
        titleLabel.textColor = option.color
        
        if #available(OSX 10.14, *) {
            iconImageView.contentTintColor = option.color
        }
        
        if let iconText = option.icon {
            iconLabel.stringValue = iconText
            iconLabel.isHidden = false
        } else if let iconImage = option.iconImage {
            iconImageView.image = NSImage(named: iconImage)
            iconImageView.isHidden = false
        }
        
        titleLabel.stringValue = option.title
        separator.isHidden = !option.showLine
        
        separator.fillColor = NSColor.Sphinx.Text.withAlphaComponent(0.2)
        
        let hasIcon = (option.icon != nil || option.iconImage != nil)
        labelLeadingConstraint.constant = hasIcon ? 40 : 10
        self.layoutSubtreeIfNeeded()
    }
    
    @IBAction func buttonClicked(_ sender: Any) {
        if buttonTag >= 0 {
            delegate?.didTapButton(tag: buttonTag)
        }
    }
}
