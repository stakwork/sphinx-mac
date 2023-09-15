//
//  SentPaidDetails.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 15/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class SentPaidDetails: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!

    @IBOutlet weak var priceLabel: NSTextField!
    @IBOutlet weak var statusLabel: NSTextField!
    
    static let kViewHeight: CGFloat = 36
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setup()
    }
    
    func setup() {}
    
    func configureWith(
        paidContent: BubbleMessageLayoutState.PaidContent
    ) {
        priceLabel.stringValue = "\(paidContent.price.formattedWithSeparator) SAT"
        statusLabel.stringValue = paidContent.statusTitle
    }
    
}
