//
//  PaymentInvoiceBubbleView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PaymentInvoiceBubbleView: CommonBubbleView {
    
    public static let kInvoiceBottomBubbleHeight:CGFloat = 75
    public static let kInvoiceMessageSideMargin:CGFloat = 30
    public static let kInvoiceLabelTopMargin:CGFloat = 23
    public static let kInvoiceMessageBottomMargin:CGFloat = 65
    
    func showIncomingDirectPaymentBubble(messageRow: TransactionMessageRow, size: CGSize, hasImage: Bool) {
        showOutgoingPaidInvoiceBubble(messageRow: messageRow, size: size, hasImage: hasImage)
    }
    
    func showOutgoingDirectPaymentBubble(messageRow: TransactionMessageRow, size: CGSize, hasImage: Bool) {
        showIncomingPaidInvoiceBubble(messageRow: messageRow, size: size, hasImage: hasImage)
    }
    
    func showIncomingPaidInvoiceBubble(messageRow: TransactionMessageRow, size: CGSize, hasImage: Bool = false) {
        clearSubview(view: self)

        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: false, nextBubble: hasImage)
        let bezierPath = getOutgoingBezierPath(size: size, bubbleMargin: 6, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
        let bubbleColors = getBubbleColors(messageRow: messageRow, incoming: false)

        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.fillColor = bubbleColors.0
        layer.strokeColor = bubbleColors.1
        layer.name = CommonBubbleView.kBubbleLayerName
        
        if messageRow.transactionMessage.isDirectPayment() {
            layer.name = CommonBubbleView.kBubbleLayerName
        }

        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.layer?.addSublayer(layer)
        self.addMessageShadow(layer: layer)
    }
    
    func showOutgoingPaidInvoiceBubble(messageRow: TransactionMessageRow, size: CGSize, hasImage: Bool = false) {
        clearSubview(view: self)

        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: false, nextBubble: hasImage)
        let bezierPath = getIncomingBezierPath(size: size, bubbleMargin: Constants.kBubbleReceivedArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
        let bubbleColors = getBubbleColors(messageRow: messageRow, incoming: true)

        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.fillColor = bubbleColors.0
        layer.strokeColor = bubbleColors.1
        layer.name = CommonBubbleView.kBubbleLayerName
        
        if messageRow.transactionMessage.isDirectPayment() {
            layer.name = CommonBubbleView.kBubbleLayerName
        }

        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.layer?.addSublayer(layer)
        self.addMessageShadow(layer: layer)
    }
    
    func showIncomingExpiredInvoiceBubble(messageRow: TransactionMessageRow, bubbleWidth: CGFloat) {
        showExpiredInvoiceBubble(messageRow: messageRow, bubbleWidth: bubbleWidth, sent: false)
    }

    func showOutgoingExpiredInvoiceBubble(messageRow: TransactionMessageRow, bubbleWidth: CGFloat) {
        showExpiredInvoiceBubble(messageRow: messageRow, bubbleWidth: bubbleWidth, sent: true)
    }

    func showExpiredInvoiceBubble(messageRow: TransactionMessageRow, bubbleWidth: CGFloat, sent: Bool) {
        clearSubview(view: self)

        let bubbleHeight = CommonExpiredInvoiceCollectionViewItem.kExpiredBubbleHeight
        let bubbleColor = getBubbleColors(messageRow: messageRow, incoming: messageRow.isIncoming())

        let consecutiveBubbles = ConsecutiveBubbles(previousBubble: false, nextBubble: false)
        let size = CGSize(width: bubbleWidth, height: bubbleHeight)
        let bezierPath : NSBezierPath?
        if sent {
            bezierPath = getOutgoingBezierPath(size: size, bubbleMargin: 6, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
        } else {
            bezierPath = getIncomingBezierPath(size: size, bubbleMargin: Constants.kBubbleReceivedArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
        }

        let layer = CAShapeLayer()
        layer.path = bezierPath!.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.fillColor = bubbleColor.0
        layer.strokeColor = bubbleColor.1
        layer.name = CommonBubbleView.kBubbleLayerName

        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.layer?.addSublayer(layer)
        self.addMessageShadow(layer: layer)
    }
}
