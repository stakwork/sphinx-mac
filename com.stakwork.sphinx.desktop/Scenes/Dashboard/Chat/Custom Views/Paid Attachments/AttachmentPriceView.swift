//
//  AttachmentPriceView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class AttachmentPriceView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var priceLabelContainer: NSBox!
    @IBOutlet weak var priceLabel: NSTextField!
    @IBOutlet weak var statusLabelContainer: NSBox!
    @IBOutlet weak var statusLabel: NSTextField!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
   
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        priceLabelContainer.wantsLayer = true
        statusLabelContainer.wantsLayer = true
        priceLabelContainer.layer?.cornerRadius = 5
        statusLabelContainer.layer?.cornerRadius = 5
    }
    
    func configure(price: Int = 0, status: (String, NSColor), forceShow: Bool = false) {
        self.isHidden = price <= 0 && !forceShow
        let priceString = price.formattedWithSeparator
        priceLabel.stringValue = "\(priceString) SAT"
        statusLabelContainer.fillColor = status.1
        statusLabel.stringValue = status.0
    }
}
