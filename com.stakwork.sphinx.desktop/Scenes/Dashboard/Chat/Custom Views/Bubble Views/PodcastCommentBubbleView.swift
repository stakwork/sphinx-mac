//
//  PodcastCommentBubbleView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

class PodcastCommentBubbleView: CommonBubbleView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func showIncomingPodcastCommentBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let isPaidAttachment = messageRow.isPaidAttachment
        let attachmentHasText = messageRow.transactionMessage.hasMessageContent()
        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: messageRow.isReply, nextBubble: attachmentHasText || isPaidAttachment)
        showIncomingEmptyBubble(messageRow: messageRow, size: size, consecutiveBubbles: consecutiveBubbles)
    }
    
    func showOutgoingPodcastCommentBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let attachmentHasText = messageRow.transactionMessage.hasMessageContent()
        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: messageRow.isReply, nextBubble: attachmentHasText)
        showOutgoingEmptyBubble(messageRow: messageRow, size: size, consecutiveBubbles: consecutiveBubbles)
    }
}
