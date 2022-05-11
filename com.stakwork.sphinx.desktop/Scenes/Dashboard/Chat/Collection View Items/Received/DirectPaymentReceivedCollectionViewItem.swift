//
//  DirectPaymentReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class DirectPaymentReceivedCollectionViewItem: CommonDirectPaymentCollectionViewItem {
    
    @IBOutlet weak var paymentDetailsContainer: NSView!
    @IBOutlet weak var tribePaymentDetailsContainer: NSView!
    @IBOutlet weak var tribePaymentIcon: NSImageView!
    @IBOutlet weak var tribePaymentAmountLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, incoming: true, chatWidth: chatWidth)
        
        configureTribePaymentLayout(messageRow: messageRow, contact: contact, chat: chat)
    }
    
    func configureTribePaymentLayout(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?) {
        paymentDetailsContainer.isHidden = (chat?.isPublicGroup() ?? false)
        tribePaymentDetailsContainer.isHidden = !(chat?.isPublicGroup() ?? false)

        setTribePaymentAmount(messageRow: messageRow)
    }
    
    func setTribePaymentAmount(messageRow: TransactionMessageRow) {
        let amountString = messageRow.getAmountString()
        tribePaymentAmountLabel.stringValue = amountString
    }
}
