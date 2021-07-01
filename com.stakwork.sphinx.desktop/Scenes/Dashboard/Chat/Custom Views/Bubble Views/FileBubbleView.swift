//
//  FileBubbleView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class FileBubbleView: CommonBubbleView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func showIncomingFileBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let isPaidAttachment = messageRow.isPaidAttachment
        let attachmentHasText = messageRow.transactionMessage.hasMessageContent()
        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: messageRow.isReply, nextBubble: attachmentHasText || isPaidAttachment)
        showIncomingEmptyBubble(messageRow: messageRow, size: size, consecutiveBubbles: consecutiveBubbles)
    }
    
    func showOutgoingFileBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let attachmentHasText = messageRow.transactionMessage.hasMessageContent()
        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: messageRow.isReply, nextBubble: attachmentHasText)
        showOutgoingEmptyBubble(messageRow: messageRow, size: size, consecutiveBubbles: consecutiveBubbles)
    }
}
