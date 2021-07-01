//
//  VideoCallSentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class VideoCallSentCollectionViewItem: CommonVideoCallCollectionViewItem {
    
    @IBOutlet weak var seenSign: NSTextField!
//    @IBOutlet weak var errorContainer: UIView!
//    @IBOutlet weak var errorMessageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configureMessageStatus()
        
        let bubbleSize = CommonVideoCallCollectionViewItem.getBubbleSize(messageRow: messageRow)
        bubbleView.showOutgoingVideoCallBubble(messageRow: messageRow, size: bubbleSize)

        if messageRow.shouldShowRightLine {
           addRightLine()
        }

        if messageRow.shouldShowLeftLine {
           addLeftLine()
        }
    }
    
    func configureMessageStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        let received = messageRow.transactionMessage.received()
        configureLockSign()
        
        seenSign.stringValue = received ? "flash_on" : ""
        seenSign.alphaValue = received ? 1.0 : 0.0
        
//        let failed = messageRow.transactionMessage.failed()
//        let expired = messageRow.transactionMessage.isMediaExpired()
//        errorContainer.alpha = failed || expired ? 1.0 : 0.0
//        errorMessageLabel.text = expired ? "Media terms expired" : "Message Failed"
    }
    
}
