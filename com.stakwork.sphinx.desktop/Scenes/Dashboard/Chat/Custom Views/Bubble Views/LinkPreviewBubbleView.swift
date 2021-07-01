//
//  LinkPreviewBubbleView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 15/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class LinkPreviewBubbleView : CommonBubbleView {
    
    func addConstraintsTo(bubbleView: NSView, messageRow: TransactionMessageRow) {
        let leftMargin = messageRow.isIncoming() ? Constants.kBubbleReceivedArrowMargin : 0
        let height = CommonChatCollectionViewItem.getLinkPreviewHeight(messageRow: messageRow) - Constants.kBubbleBottomMargin
        let width = getViewWidth(messageRow: messageRow)
        
        for c in  self.constraints {
            self.removeConstraint(c)
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: leftMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: height).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: width).isActive = true
    }
    
    func getViewWidth(messageRow: TransactionMessageRow) -> CGFloat {
        let isIncoming = messageRow.isIncoming()
        let leftMargin = isIncoming ? Constants.kBubbleReceivedArrowMargin : 0
        let rightMargin = isIncoming ? 0 : Constants.kBubbleSentArrowMargin
        
        return MessageBubbleView.kBubbleLinkPreviewWidth - rightMargin - leftMargin
    }
    
    func showIncomingLinkBubble(messageRow: TransactionMessageRow, size: CGSize, consecutiveBubble: ConsecutiveBubbles? = nil, bubbleMargin: CGFloat? = nil, existingObject: Bool) {
        if existingObject {
            showIncomingEmptyBubble(messageRow: messageRow, size: size, consecutiveBubbles: consecutiveBubble, bubbleMargin: bubbleMargin)
        } else {
            let consecutiveBubbles = consecutiveBubble ?? ConsecutiveBubbles(previousBubble: false, nextBubble: false)
            let bezierPath = getIncomingBezierPath(size: size, bubbleMargin: bubbleMargin ?? Constants.kBubbleReceivedArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
            
            let color = messageRow.isIncoming() ? NSColor.Sphinx.LinkReceivedColor : NSColor.Sphinx.LinkSentColor
            let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            addDashedLineBorder(frame: frame, color: color, bezierPath: bezierPath)
        }
    }
    
    func showOutgoingLinkBubble(messageRow: TransactionMessageRow, size: CGSize, consecutiveBubble: ConsecutiveBubbles? = nil, bubbleMargin: CGFloat? = nil, xPosition: CGFloat? = nil, existingObject: Bool) {
        if existingObject {
            showOutgoingEmptyBubble(messageRow: messageRow, size: size, consecutiveBubbles: consecutiveBubble, bubbleMargin: bubbleMargin)
        } else {
            let consecutiveBubbles = consecutiveBubble ?? ConsecutiveBubbles(previousBubble: false, nextBubble: false)
            let bezierPath = getOutgoingBezierPath(size: size, bubbleMargin: bubbleMargin ?? Constants.kBubbleSentArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)

            let color = messageRow.isIncoming() ? NSColor.Sphinx.LinkReceivedColor : NSColor.Sphinx.LinkSentColor
            let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            addDashedLineBorder(frame: frame, color: color, bezierPath: bezierPath)
        }
    }
    
    func addDashedLineBorder(frame: CGRect, color: NSColor, bezierPath: NSBezierPath) {
        clearBubbleLayer(view: self)
        
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        shapeLayer.path = bezierPath.cgPath
        shapeLayer.frame = frame
        shapeLayer.fillColor = NSColor.clear.cgColor
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = 1.5
        shapeLayer.lineJoin = .round
        shapeLayer.lineDashPattern = [8,4]
        shapeLayer.name = CommonBubbleView.kInvoiceDashedLayerName
        
        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.layer?.addSublayer(shapeLayer)
    }
}
