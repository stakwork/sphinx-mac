//
//  PodcastBoostReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PodcastBoostReceivedCollectionViewItem: CommonPodcastBoostCollectionViewItem {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
 
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
            super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

            commonConfigurationForMessages()
            configureStatus()
            
            let bubbleSize = CGSize(width: CommonPodcastBoostCollectionViewItem.kReceivedBubbleWidth, height: CommonPodcastBoostCollectionViewItem.kBubbleHeight)
            bubbleView.showIncomingPodcastBoostBubble(messageRow: messageRow, size: bubbleSize)

            if messageRow.shouldShowRightLine {
                addRightLine()
            }

            if messageRow.shouldShowLeftLine {
                addLeftLine()
            }
        }
        
        func configureStatus() {
//    //        guard let messageRow = messageRow else {
//    //            return
//    //        }
//
//            configureLockSign()
//    //
//    //        let expired = messageRow.transactionMessage.isMediaExpired()
//    //        errorContainer.alpha = expired ? 1.0 : 0.0
        }
}
