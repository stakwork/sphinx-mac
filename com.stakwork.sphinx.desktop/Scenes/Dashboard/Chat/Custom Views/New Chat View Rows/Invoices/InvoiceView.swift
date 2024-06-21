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
    @IBOutlet weak var memoLabel: MessageTextField!
    @IBOutlet weak var payButtonContainer: NSView!
    @IBOutlet weak var payButtonView: NSBox!
    @IBOutlet weak var payButton: CustomButton!
    
    @IBOutlet weak var borderView: NSBox!
    
    static let kViewOutgoingHeight: CGFloat = 53
    static let kViewIncomingHeight: CGFloat = 106
    
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
        memoLabel.setSelectionColor(color: NSColor.getTextSelectionColor())
        memoLabel.allowsEditingTextAttributes = true
        
        payButton.cursor = .pointingHand
    }
    
    func configureWith(
        invoice: BubbleMessageLayoutState.Invoice,
        bubble: BubbleMessageLayoutState.Bubble,
        and delegate: InvoiceViewDelegate?
    ) {
        self.delegate = delegate
        
        self.alphaValue = (invoice.isExpired && !invoice.isPaid) ? 0.4 : 1.0
        
        addDashdBorder(invoice: invoice, bubble: bubble)
        
        memoLabel.font = invoice.font
        unitLabel.textColor = bubble.direction.isIncoming() ? NSColor.Sphinx.WashedOutReceivedText : NSColor.Sphinx.WashedOutSentText
        
        if let memo = invoice.memo, memo.isNotEmpty {
            memoContainerView.isHidden = false
            memoLabel.stringValue = memo
        } else {
            memoContainerView.isHidden = true
        }
        
        amountLabel.stringValue = invoice.amount.formattedWithSeparator
        
        payButtonContainer.isHidden = invoice.isPaid || bubble.direction.isOutgoing()
        
        if invoice.isPaid {
            if bubble.direction.isOutgoing() {
                icon.image = NSImage(named: "invoicePayIcon")
                icon.contentTintColor = NSColor.Sphinx.Text
            } else {
                icon.image = NSImage(named: "invoiceReceiveIcon")
                icon.contentTintColor = NSColor.Sphinx.PrimaryBlue
            }
        } else {
            icon.image = NSImage(named: "qrCode")
            icon.contentTintColor = NSColor.Sphinx.Text
        }
    }
    
    func addDashdBorder(
        invoice: BubbleMessageLayoutState.Invoice,
        bubble: BubbleMessageLayoutState.Bubble
    ) {
        borderView.removeDashBorder()
        
        let shouldDrawBorder = !invoice.isPaid && !invoice.isExpired
        
        if shouldDrawBorder {
            
            var viewsHeight: CGFloat = 0
            
            if bubble.direction == .Incoming {
                viewsHeight += InvoiceView.kViewIncomingHeight
            } else {
                viewsHeight += InvoiceView.kViewOutgoingHeight
            }
            
            if let memo = invoice.memo, memo.isNotEmpty {
                let textHeight = ChatHelper.getTextHeightFor(
                    text: memo,
                    width: CommonNewMessageCollectionViewitem.kMaximumPaidTextViewBubbleWidth
                ) - 16
                
                viewsHeight += textHeight
            }
            
            borderView.addDashedBorder(
                color: bubble.direction.isIncoming() ? NSColor.Sphinx.PrimaryGreen : NSColor.Sphinx.SecondaryText,
                fillColor: NSColor.Sphinx.Body,
                size: CGSize(width: CommonNewMessageCollectionViewitem.kMaximumInvoiceBubbleWidth, height: viewsHeight),
                lineWidth: 2,
                radius: 8
            )
        }
    }
    
    @IBAction func payButtonClicked(_ sender: Any) {
        delegate?.didTapInvoicePayButton()
    }
    
}
