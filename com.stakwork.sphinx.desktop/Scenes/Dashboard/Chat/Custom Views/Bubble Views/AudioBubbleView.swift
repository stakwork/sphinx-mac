//
//  AudioBubbleView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 26/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class AudioBubbleView: CommonBubbleView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func showIncomingAudioBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: messageRow.isReply, nextBubble: false)
        showIncomingEmptyBubble(messageRow: messageRow, size: size, consecutiveBubbles: consecutiveBubbles)
    }
    
    func showOutgoingAudioBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: messageRow.isReply, nextBubble: false)
        showOutgoingEmptyBubble(messageRow: messageRow, size: size, consecutiveBubbles: consecutiveBubbles)
    }
}
