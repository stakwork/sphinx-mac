//
//  PodcastBoostSentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PodcastBoostSentCollectionViewItem: CommonPodcastBoostCollectionViewItem {
    
    @IBOutlet weak var seenSign: NSTextField!
    @IBOutlet weak var errorSign: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configureMessageStatus()
        
        let bubbleSize = CGSize(width: CommonPodcastBoostCollectionViewItem.kSentBubbleWidth, height: CommonPodcastBoostCollectionViewItem.kBubbleHeight)
        bubbleView.showOutgoingPodcastBoostBubble(messageRow: messageRow, size: bubbleSize)

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
        
        configureLockSign()
        
        let received = messageRow.transactionMessage.received()
        let failed = messageRow.transactionMessage.failed()
        
        seenSign.stringValue = received ? "flash_on" : ""
        seenSign.alphaValue = received ? 1.0 : 0.0
        errorSign.alphaValue = failed ? 1.0 : 0.0
    }
}
