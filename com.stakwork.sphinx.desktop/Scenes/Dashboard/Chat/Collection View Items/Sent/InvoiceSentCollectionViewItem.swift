//
//  InvoiceSentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class InvoiceSentCollectionViewItem: CommonInvoiceCollectionViewItem {
    
    @IBOutlet weak var seenSign: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        commonConfigurationForMessages()
        
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        
        let received = messageRow.transactionMessage.received()
        seenSign.stringValue = received ? "flash_on" : ""
    }
    
    override func getBorderColor() -> NSColor {
        return NSColor.Sphinx.SecondaryText
    }
    
    override func getBubbleSize(messageRow: TransactionMessageRow) -> CGSize {
        let labelHeight = InvoiceSentCollectionViewItem.getLabelHeight(messageRow: messageRow)
        let bubbleHeight = labelHeight + CommonInvoiceCollectionViewItem.kLabelTopMargin + CommonInvoiceCollectionViewItem.kLabelBottomMarginWithoutButton
        return CGSize(width: CommonInvoiceCollectionViewItem.kBubbleWidth, height: bubbleHeight)
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let labelHeight = getLabelHeight(messageRow: messageRow)
        return labelHeight + kLabelTopMargin + kLabelBottomMarginWithoutButton + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin
    }
}
