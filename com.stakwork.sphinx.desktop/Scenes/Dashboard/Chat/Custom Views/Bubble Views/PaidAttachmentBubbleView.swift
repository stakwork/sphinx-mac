//
//  PaidAttachmentBubbleView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PaidAttachmentBubbleView: CommonBubbleView {
    
    let kPaidAttachmentWidth: CGFloat = 250
    let kPaidAttachmentHeight: CGFloat = 50
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func showPaidAttachmentBubble(nextMessage: Bool, color: NSColor) {
        self.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let size = CGSize(width: self.frame.size.width, height: kPaidAttachmentHeight)
        let consecutiveBubbles = CommonBubbleView.ConsecutiveBubbles(previousBubble: true, nextBubble: false)
        let consecutiveMessages = TransactionMessage.ConsecutiveMessages(previousMessage: true, nextMessage: nextMessage)
        let bezierPath = getIncomingBezierPath(size: size, bubbleMargin: Constants.kBubbleReceivedArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: consecutiveMessages)

        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.fillColor = color.cgColor
        layer.strokeColor = color.cgColor
        layer.lineWidth = 1
        layer.name = CommonBubbleView.kBubbleLayerName
        
        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.layer?.addSublayer(layer)
        self.addMessageShadow(layer: layer)
    }
}
