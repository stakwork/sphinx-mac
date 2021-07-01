//
//  DirectPaymentSentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class DirectPaymentSentCollectionViewItem: CommonDirectPaymentCollectionViewItem {

    @IBOutlet weak var seenSign: NSTextField!
    @IBOutlet weak var errorSign: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, incoming: false, chatWidth: chatWidth)
        
        configureMessageStatus()
    }
    
    func configureMessageStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        let failed = messageRow.transactionMessage.failed()
        let encrypted = messageRow.encrypted
        
        seenSign.alphaValue = failed ? 0.0 : 1.0
        lockSign.stringValue = (encrypted && !failed) ? "lock" : ""
        errorSign.alphaValue = failed ? 1.0 : 0.0
    }
}
