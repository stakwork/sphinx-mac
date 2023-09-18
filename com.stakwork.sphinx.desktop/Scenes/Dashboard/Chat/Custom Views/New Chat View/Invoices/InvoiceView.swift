//
//  InvoiceView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol InvoiceViewDelegate: AnyObject {
    func didTapInvoicePayButton()
}

class InvoiceView: NSView, LoadableNib {
    
    weak var delegate: InvoiceViewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var icon: NSImageView!
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var unitLabel: NSTextField!
    @IBOutlet weak var memoContainerView: NSView!
    @IBOutlet weak var memoLabel: CCTextField!
    @IBOutlet weak var payButtonContainer: NSView!
    @IBOutlet weak var payButtonView: NSBox!
    @IBOutlet weak var payButton: CustomButton!
    
    @IBOutlet weak var borderView: NSBox!
    
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
        payButton.cursor = .pointingHand
    }
    
    func configureWith(
        invoice: BubbleMessageLayoutState.Invoice,
        bubble: BubbleMessageLayoutState.Bubble,
        and delegate: InvoiceViewDelegate?
    ) {
        self.delegate = delegate
        
        self.alphaValue = (invoice.isExpired && !invoice.isPaid) ? 0.4 : 1.0
        
        borderView.removeDashBorder()
        
        let shouldDrawBorder = !invoice.isPaid && !invoice.isExpired
        
        if shouldDrawBorder {
            borderView.addDashedBorder(
                color: bubble.direction.isIncoming() ? NSColor.Sphinx.PrimaryGreen : NSColor.Sphinx.SecondaryText,
                size: CGSize(width: CommonNewMessageCollectionViewitem.kMaximumInvoiceBubbleWidth, height: self.borderView.frame.height),
                radius: 0
            )
        }
        
        memoLabel.font = invoice.font
        unitLabel.textColor = bubble.direction.isIncoming() ? NSColor.Sphinx.WashedOutReceivedText : NSColor.Sphinx.WashedOutSentText
        
        if let memo = invoice.memo {
            memoContainerView.isHidden = false
            memoLabel.stringValue = memo
        } else {
            memoContainerView.isHidden = true
        }
        
        amountLabel.stringValue = invoice.amount.formattedWithSeparator
        
        payButtonContainer.isHidden = invoice.isPaid || bubble.direction.isOutgoing()
        
        if invoice.isPaid {
            if bubble.direction.isOutgoing() {
                icon.image = NSImage(named: "invoice-pay-button")
                icon.contentTintColor = NSColor.Sphinx.Text
            } else {
                icon.image = NSImage(named: "invoice-receive-icon")
                icon.contentTintColor = NSColor.Sphinx.PrimaryBlue
            }
        } else {
            icon.image = NSImage(named: "qr_code")
            icon.contentTintColor = NSColor.Sphinx.Text
        }
    }
    
    @IBAction func payButtonClicked(_ sender: Any) {
        delegate?.didTapInvoicePayButton()
    }
    
}
