//
//  TribeTagView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/10/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol TribeTagViewDelegate: AnyObject {
    func didTapOnTag(tag: Int, selected: Bool)
}

@IBDesignable
class TribeTagView: NSView, LoadableNib {
    
    weak var delegate: TribeTagViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var tagBox: NSBox!
    @IBOutlet weak var tagImage: NSImageView!
    @IBOutlet weak var tagName: NSTextField!
    
    var selected = false
    
    @IBInspectable var tagNameString: String = "" {
        didSet {
            self.tagName.stringValue = tagNameString
        }
    }
    
    @IBInspectable var tagImageName: String = "" {
        didSet {
            tagImage.image = NSImage(named: tagImageName)
        }
    }
    
    @IBInspectable var tagIdentifier: Int = 0
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        tagImage.layer?.cornerRadius = tagImage.frame.size.height / 2
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    func configure(selectedValue: Bool) {
        selected = selectedValue
        tagBox.fillColor = selectedValue ? NSColor.Sphinx.ReceivedMsgBG : NSColor.Sphinx.Body
    }
    
    @IBAction func tagButtonClicked(_ sender: Any) {
        configure(selectedValue: !selected)
        delegate?.didTapOnTag(tag: self.tagIdentifier, selected: selected)
    }
}
