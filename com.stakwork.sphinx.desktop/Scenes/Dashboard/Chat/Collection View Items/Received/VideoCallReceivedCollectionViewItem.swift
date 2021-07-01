//
//  VideoCallReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class VideoCallReceivedCollectionViewItem: CommonVideoCallCollectionViewItem {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configureStatus()
        
        let bubbleSize = CommonVideoCallCollectionViewItem.getBubbleSize(messageRow: messageRow)
        bubbleView.showIncomingVideoCallBubble(messageRow: messageRow, size: bubbleSize)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configureStatus() {
        configureLockSign()
    }
    
}
