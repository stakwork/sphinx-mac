//
//  PodcastBoostBubbleView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

class PodcastBoostBubbleView: CommonBubbleView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func showIncomingPodcastBoostBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: false, nextBubble: false)
        showIncomingEmptyBubble(messageRow: messageRow, size: size, consecutiveBubbles: consecutiveBubbles)
    }
    
    func showOutgoingPodcastBoostBubble(messageRow: TransactionMessageRow, size: CGSize) {
        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: false, nextBubble: false)
        showOutgoingEmptyBubble(messageRow: messageRow, size: size, consecutiveBubbles: consecutiveBubbles)
    }
}
