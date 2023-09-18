//
//  InvoicePaymentView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class InvoicePaymentView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var invoiceDetailsLabel: NSTextField!
    
    static let kViewHeight: CGFloat = 20
    
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
        payment: BubbleMessageLayoutState.Payment,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        invoiceDetailsLabel.alignment = bubble.direction.isIncoming() ? .left : .right
        
        let dateString = payment.date.getStringDate(format: "EEEE, MMM dd")
        let amountString = payment.amount.formattedWithSeparator
        invoiceDetailsLabel.stringValue = String(format: "invoice.amount.paid.on".localized, amountString, dateString)
    }
}
