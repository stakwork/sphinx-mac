//
//  CommonExpiredInvoiceCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonExpiredInvoiceCollectionViewItem : CommonChatCollectionViewItem {
    
    @IBOutlet weak var bubbleView: PaymentInvoiceBubbleView!
    @IBOutlet weak var qrCodeIcon: NSImageView!
    @IBOutlet weak var expiredInvoiceLine: NSView!
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var unitLabel: NSTextField!
    @IBOutlet weak var bubbleWidth: NSLayoutConstraint!
    
    public static var kExpiredBubbleHeight: CGFloat = 60
    public static var kExpiredBubbleMinimumWidth: CGFloat = 180
    public static var kAmountLabelSideMargins: CGFloat = 115
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        
        let bubbleW = CommonExpiredInvoiceCollectionViewItem.getExpiredInvoiceBubbleWidth(messageRow: messageRow)
        bubbleWidth.constant = bubbleW
        
        commonConfigurationForMessages()
        
        if messageRow.isIncoming() {
            bubbleView.showIncomingExpiredInvoiceBubble(messageRow: messageRow, bubbleWidth: bubbleW)
        } else {
            bubbleView.showOutgoingExpiredInvoiceBubble(messageRow: messageRow, bubbleWidth: bubbleW)
        }
        
        let amountString = messageRow.getAmountString()
        amountLabel.stringValue = "\(amountString)"
        
        drawDiagonalLine(lineContainer: expiredInvoiceLine, incoming: messageRow.isIncoming())
        
        if messageRow.shouldShowRightLine {
            addRightLine()
        }
        
        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func drawDiagonalLine(lineContainer: NSView, incoming: Bool) {
        let bezierPath = NSBezierPath()
        bezierPath.move(to: CGPoint(x: 0, y: 25))
        bezierPath.line(to: CGPoint(x: 25, y: 0))
        
        let whiteLineLayer = CAShapeLayer()
        whiteLineLayer.path = bezierPath.cgPath
        whiteLineLayer.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        whiteLineLayer.lineWidth = 5
        whiteLineLayer.strokeColor = (incoming ? NSColor.Sphinx.OldReceivedMsgBG : NSColor.Sphinx.OldSentMsgBG).cgColor
        
        let redLineLayer = CAShapeLayer()
        redLineLayer.path = bezierPath.cgPath
        redLineLayer.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        redLineLayer.lineWidth = 1
        redLineLayer.strokeColor = NSColor(hex: "#ff6f6f").cgColor
        
        lineContainer.wantsLayer = true
        lineContainer.layer?.addSublayer(whiteLineLayer)
        lineContainer.layer?.addSublayer(redLineLayer)
    }
    
    static func getAmountLabelAttributes(messageRow: TransactionMessageRow) -> (String, NSColor, NSFont) {
        let incoming = messageRow.isIncoming()
        let font = CommonChatCollectionViewItem.kAmountFont
        let color = incoming ? NSColor.Sphinx.WashedOutReceivedText : NSColor.Sphinx.WashedOutSentText
        let amountString = messageRow.getAmountString()
        return (amountString, color, font)
    }
    
    public static func getExpiredInvoiceBubbleWidth(messageRow: TransactionMessageRow) -> CGFloat {
        let amountLabelAttributes = getAmountLabelAttributes(messageRow: messageRow)
        let amountLabelWidth = MessageBubbleView.getLabel(textColorAndFont: amountLabelAttributes).1.width
        let amountBubbleWidth = amountLabelWidth + CommonExpiredInvoiceCollectionViewItem.kAmountLabelSideMargins
        let bubbleWidth = (amountBubbleWidth < CommonExpiredInvoiceCollectionViewItem.kExpiredBubbleMinimumWidth) ? CommonExpiredInvoiceCollectionViewItem.kExpiredBubbleMinimumWidth : amountBubbleWidth
        return bubbleWidth
    }
    
    public static func getRowHeight() -> CGFloat {
        return CommonExpiredInvoiceCollectionViewItem.kExpiredBubbleHeight + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin
    }
}
