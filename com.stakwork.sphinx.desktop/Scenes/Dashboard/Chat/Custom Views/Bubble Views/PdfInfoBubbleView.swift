//
//  PdfInfoBubbleView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 24/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PdfInfoBubbleView: CommonBubbleView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func showPdfInfoBubbleView(message: TransactionMessage) {
        self.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let width = (Constants.kPictureBubbleHeight - (message.isOutgoing() ? Constants.kBubbleSentArrowMargin  : Constants.kBubbleReceivedArrowMargin)) + 1
        let size = CGSize(width: width, height: Constants.kFileBubbleHeight)
        let consecutiveBubbles = CommonBubbleView.ConsecutiveBubbles(previousBubble: true, nextBubble: message.hasMessageContent())
        let consecutiveMessages = TransactionMessage.ConsecutiveMessages(previousMessage: true, nextMessage: message.consecutiveMessages.nextMessage)
        
        var bezierPath : NSBezierPath? = nil
        if message.isOutgoing() {
            bezierPath = getOutgoingBezierPath(size: size, bubbleMargin: 0, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: consecutiveMessages)
        } else {
            bezierPath = getIncomingBezierPath(size: size, bubbleMargin: 0, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: consecutiveMessages)
        }

        let layer = CAShapeLayer()
        layer.path = bezierPath!.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.fillColor = NSColor(hex: "#3C3F41").cgColor
        layer.strokeColor = NSColor(hex: "#3C3F41").cgColor
        layer.lineWidth = 1
        layer.name = CommonBubbleView.kBubbleLayerName
        
        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.layer?.addSublayer(layer)
    }
}
