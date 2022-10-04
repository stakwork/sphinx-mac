//
//  TribeTagView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/10/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa

@IBDesignable
class TribeTagView: NSView, LoadableNib {
    
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
    
    @IBInspectable var tagIdentifier: String = ""
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        tagImage.layer?.cornerRadius = tagImage.frame.size.height / 2
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    @IBAction func tagButtonClicked(_ sender: Any) {
        selected = !selected
        
        tagBox.fillColor = selected ? NSColor.Sphinx.ReceivedMsgBG : NSColor.Sphinx.Body
    }
}
