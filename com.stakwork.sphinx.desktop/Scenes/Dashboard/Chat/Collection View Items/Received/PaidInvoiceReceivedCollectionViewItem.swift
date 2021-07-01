//
//  PaidInvoiceReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PaidInvoiceReceivedCollectionViewItem: CommonPaidInvoiceCollectionViewItem {
    
    @IBOutlet weak var bottomRightLineContainer: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configurePaidInvoice()

        bottomRightLineContainer?.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }

        if messageRow.shouldShowRightLine {
            addRightLine()
        } else if messageRow.transactionMessage.isPaid() {
            addBottomRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func addBottomRightLine() {
        if let bottomRightLineContainer = bottomRightLineContainer {
            bottomRightLineContainer.wantsLayer = true
            
            let y:CGFloat = 0
            let lineFrame = CGRect(x: 0.0, y: y, width: 3, height: bottomRightLineContainer.frame.size.height - y)
            let lineLayer = getVerticalDottedLine(color: NSColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
            bottomRightLineContainer.layer?.addSublayer(lineLayer)
        }
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let labelHeight = CommonPaidInvoiceCollectionViewItem.getLabelHeight(messageRow: messageRow)
        
        return labelHeight + CommonInvoiceCollectionViewItem.kLabelTopMargin + CommonInvoiceCollectionViewItem.kLabelBottomMarginWithoutButton + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin
    }
}
