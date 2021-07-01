//
//  PaymentSentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PaymentSentCollectionViewItem: CommonPaymentCollectionViewItem {

    @IBOutlet weak var topRightLineContainer: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        
        commonConfigurationForMessages()
        configurePayment()
        addSmallRightLine()
        
        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func addSmallRightLine() {
        topRightLineContainer.wantsLayer = true
        
        topRightLineContainer.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        let lineFrame = CGRect(x: 0, y: 1, width: 3, height: topRightLineContainer.frame.size.height)
        let lineLayer = getVerticalDottedLine(color: NSColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
        topRightLineContainer.layer?.addSublayer(lineLayer)
    }
}
