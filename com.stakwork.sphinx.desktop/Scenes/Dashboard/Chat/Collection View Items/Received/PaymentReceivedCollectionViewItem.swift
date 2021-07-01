//
//  PaymentReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PaymentReceivedCollectionViewItem: CommonPaymentCollectionViewItem {
    
    @IBOutlet weak var topLeftLineContainer: NSView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        
        commonConfigurationForMessages()
        configurePayment()
        addSmallLeftLine()
        
        if messageRow.shouldShowRightLine {
            addRightLine()
        }
    }
    
    func addSmallLeftLine() {
        topLeftLineContainer.wantsLayer = true
        
        topLeftLineContainer.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        let lineFrame = CGRect(x: 0, y: 1, width: 3, height: topLeftLineContainer.frame.size.height)
        let lineLayer = getVerticalDottedLine(color: NSColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
        topLeftLineContainer.layer?.addSublayer(lineLayer)
    }
}
