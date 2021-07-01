//
//  CommonPaidInvoiceCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonPaidInvoiceCollectionViewItem : CommonChatCollectionViewItem {
    
    @IBOutlet weak var bubbleView: PaymentInvoiceBubbleView!
    @IBOutlet weak var requestPaidIcon: NSImageView!
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var unitLabel: NSTextField!
    @IBOutlet weak var memoLabel: NSTextField!
    
    public static let kLabelWidth: CGFloat = 204
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configurePaidInvoice() {
        guard let messageRow = messageRow, let message = messageRow.transactionMessage else {
            return
        }
        
        let labelHeight = CommonPaidInvoiceCollectionViewItem.getLabelHeight(messageRow: messageRow)

        let bubbleHeight = labelHeight + CommonInvoiceCollectionViewItem.kLabelTopMargin + CommonInvoiceCollectionViewItem.kLabelBottomMarginWithoutButton
        let bubbleSize = CGSize(width: CommonInvoiceCollectionViewItem.kBubbleWidth, height: bubbleHeight)
        
        if message.isIncoming() {
            bubbleView.showIncomingPaidInvoiceBubble(messageRow: messageRow, size: bubbleSize)
        } else {
            bubbleView.showOutgoingPaidInvoiceBubble(messageRow: messageRow, size: bubbleSize)
        }

        let amountNumber = message.amount ?? NSDecimalNumber(value: 0)
        let amountString = Int(truncating: amountNumber).formattedWithSeparator
        amountLabel.stringValue = "\(amountString)"

        memoLabel.font = Constants.kMessageFont
        memoLabel.stringValue = messageRow.getMessageContent()
        addLinksOnLabel(label: memoLabel)
    }
    
    public static func getLabelHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let textColorAndFont = messageRow.getMessageAttributes()
        let (_, size) = MessageBubbleView.getLabel(maxWidth: kLabelWidth, textColorAndFont: textColorAndFont)
        return textColorAndFont.0.isEmpty ? -17 : size.height
    }
}
