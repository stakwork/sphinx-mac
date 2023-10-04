//
//  DirectPaymentView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class DirectPaymentView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var recipientAvatarView: ChatSmallAvatarView!
    
    @IBOutlet weak var tribeReceivedPaymentContainer: NSView!
    @IBOutlet weak var tribeReceivedPmtAmountLabel: NSTextField!
    @IBOutlet weak var tribeReceivedPmtIconImageView: NSImageView!
    
    @IBOutlet weak var receivedPaymentContainer: NSView!
    @IBOutlet weak var receivedPmtIconImageView: NSImageView!
    @IBOutlet weak var receivedPmtAmountLabel: NSTextField!
    @IBOutlet weak var receivedPmtUnitLabel: NSTextField!
    
    @IBOutlet weak var sentPaymentContainer: NSView!
    @IBOutlet weak var sentPmtAmountLabel: NSTextField!
    @IBOutlet weak var sentPmtUnitLabel: NSTextField!
    @IBOutlet weak var sentPmtIconImageView: NSImageView!
    
    static let kViewHeight: CGFloat = 56

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
    
    func setup() {
        
    }
    
    func configureWith(
        directPayment: BubbleMessageLayoutState.DirectPayment,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        let isIncoming = bubble.direction.isIncoming()
        let isTribePmt = directPayment.isTribePmt
        
        tribeReceivedPaymentContainer.isHidden = !isIncoming || !isTribePmt
        receivedPaymentContainer.isHidden = !isIncoming || isTribePmt
        sentPaymentContainer.isHidden = isIncoming
        
        let amountString = directPayment.amount.formattedWithSeparator
        tribeReceivedPmtAmountLabel.stringValue = amountString
        receivedPmtAmountLabel.stringValue = amountString
        sentPmtAmountLabel.stringValue = amountString
        
        recipientAvatarView.isHidden = true
        
        if let recipientPic = directPayment.recipientPic {
            recipientAvatarView.configureForUserWith(
                color: directPayment.recipientColor ?? NSColor.Sphinx.SecondaryText,
                alias: directPayment.recipientAlias ?? "Unknown",
                picture: recipientPic
            )
            recipientAvatarView.isHidden = false
        } else if let recipientAlias = directPayment.recipientAlias {
            recipientAvatarView.configureForUserWith(
                color: directPayment.recipientColor ?? NSColor.Sphinx.SecondaryText,
                alias: recipientAlias,
                picture: directPayment.recipientPic
            )
            recipientAvatarView.isHidden = false
        }
    }
    
}
