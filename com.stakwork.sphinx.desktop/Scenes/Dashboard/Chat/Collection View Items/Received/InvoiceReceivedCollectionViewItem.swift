//
//  InvoiceReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class InvoiceReceivedCollectionViewItem: CommonInvoiceCollectionViewItem {
    
    @IBOutlet weak var payButtonContainer: NSBox!
    @IBOutlet weak var payButton: NSButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [payButton])
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loading = false
        payButtonContainer.wantsLayer = true
        payButtonContainer.layer?.cornerRadius = 5.0
    }

    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        commonConfigurationForMessages()
        
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
    }
    
    override func getBubbleSize(messageRow: TransactionMessageRow) -> CGSize {
        let labelHeight = CommonInvoiceCollectionViewItem.getLabelHeight(messageRow: messageRow)
        let bubbleHeight = labelHeight + CommonInvoiceCollectionViewItem.kLabelTopMargin + CommonInvoiceCollectionViewItem.kLabelBottomMargin
        return CGSize(width: CommonInvoiceCollectionViewItem.kBubbleWidth, height: bubbleHeight)
    }
    
    override func getBorderColor() -> NSColor {
        return NSColor.Sphinx.PrimaryGreen
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let labelHeight = getLabelHeight(messageRow: messageRow)
        return labelHeight + kLabelTopMargin + kLabelBottomMargin + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin
    }

    @IBAction func payButtonClicked(_ sender: Any) {
        if let messageRow = self.messageRow, let message = messageRow.transactionMessage, let amount = message.amount?.intValue, amount > 0 {
            AlertHelper.showTwoOptionsAlert(title: "Confirm", message: "Do you want to pay this invoice for \(amount) sats?", confirm: {
                self.loading = true
                self.delegate?.didTapPayButton(transactionMessage: messageRow.transactionMessage, item: self)
            })
        }
    }
}
