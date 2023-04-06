//
//  MessageBubbleView.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 18/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class MessageBubbleView: CommonBubbleView {
    
    public static let kBubbleSentRightMargin: CGFloat = 9
    public static let kBubbleReceivedLeftMargin: CGFloat = 56
    
    public static let kBubbleReceivedMaxWidth: CGFloat = 515
    public static let kBubbleSentMaxWidth: CGFloat = 530
    public static let kBubbleLinkPreviewWidth: CGFloat = 400
    
    public static let kBubbleAttachmentMinimumWidht: CGFloat = 211
    public static let kMessageLabelTag : Int = 123
    
    var chatWidth: CGFloat = 0
    
    var messageRow: TransactionMessageRow? = nil

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)
        
        messageRow = nil
    }
    
    func getSubviews() -> [NSView] {
        return self.subviews
    }
    
    func clearBubbleView() {
        clearSubview(view: self)
    }
    
    public static func getLabelMargin(messageRow: TransactionMessageRow) -> CGFloat {
        return messageRow.isEmojisMessage() ? Constants.kEmojisLabelMargins : Constants.kLabelMargins
    }
    
    public static var sizeLabel: NSTextField! = nil

    public static func getLabelSize(maxWidth: CGFloat? = nil, height: CGFloat? = nil, textColorAndFont: (String, NSColor, NSFont)) -> CGSize {
        if sizeLabel == nil {
            sizeLabel = NSTextField()
            sizeLabel.isBordered = false
            sizeLabel.backgroundColor = NSColor.clear
            sizeLabel.isBezeled = false
            sizeLabel.isEditable = false
            sizeLabel.isSelectable = true
            sizeLabel.alignment = .left
        }
        sizeLabel.stringValue = textColorAndFont.0
        sizeLabel.textColor = textColorAndFont.1
        sizeLabel.font = textColorAndFont.2
        
        let size = sizeLabel.sizeThatFits(NSSize(width: maxWidth ?? .greatestFiniteMagnitude, height: height ?? .greatestFiniteMagnitude))
        return CGSize(width: size.width + 1, height: size.height)
    }
    
    public static func getLabel(maxWidth: CGFloat? = nil, height: CGFloat? = nil, textColorAndFont: (String, NSColor, NSFont)) -> (NSTextField, CGSize) {
        
        let label = MessageTextField()
        label.setColor(color: NSColor.getTextSelectionColor())
        label.isBordered = false
        label.backgroundColor = NSColor.clear
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = true
        label.alignment = .left
        label.stringValue = textColorAndFont.0
        label.textColor = textColorAndFont.1
        label.font = textColorAndFont.2
        
        let size = getLabelSize(maxWidth: maxWidth, height: height, textColorAndFont: textColorAndFont)
        label.frame.size = size
        
        if textColorAndFont.0.isEmpty {
            return (label, CGSize.zero)
        }
        
        return (label, size)
    }
    
    public static func getLabelAttributes(messageRow: TransactionMessageRow, containerViewWidth: CGFloat, bubbleMargin: CGFloat = Constants.kBubbleSentArrowMargin, labelMargin: CGFloat = Constants.kLabelMargins) -> (NSTextField, CGSize, CGSize, CGFloat) {
        
        let textColorAndFont = messageRow.getMessageAttributes()
        let labelMaxWidth = containerViewWidth - (labelMargin * 2) - bubbleMargin
        let (label, labelSize) =  getLabel(maxWidth: labelMaxWidth, textColorAndFont: textColorAndFont)
        let bubbleSize = getBubbleSize(messageRow: messageRow, labelSize: labelSize, bubbleMargin: bubbleMargin, labelMargin: labelMargin)
        
        return (label, labelSize, bubbleSize, bubbleMargin)
    }
    
    public static func getBubbleSize(messageRow: TransactionMessageRow, labelSize: CGSize, bubbleMargin: CGFloat = Constants.kBubbleSentArrowMargin, labelMargin: CGFloat = Constants.kLabelMargins) -> CGSize {
        
        let bottomBubblePadding = messageRow.isBoosted ? Constants.kReactionsViewHeight : 0
        let bubbleHeight = (labelSize.height > 0) ? labelSize.height + (labelMargin * 2) + bottomBubblePadding : bottomBubblePadding + labelMargin
        let bubbleSize = CGSize(width: labelSize.width + (labelMargin * 2) + bubbleMargin,
                                height: bubbleHeight)
        
        return bubbleSize
    }
    
    public static func getBubbleSizeFrom(messageRow: TransactionMessageRow,
                                         containerViewWidth: CGFloat,
                                         bubbleMargin: CGFloat = Constants.kBubbleSentArrowMargin,
                                         labelMargin: CGFloat = Constants.kLabelMargins) -> CGSize {
        
        let messageAttributes = messageRow.getMessageAttributes()
        let labelMaxWidth = containerViewWidth - (labelMargin * 2) - bubbleMargin
        let labelSize =  getLabelSize(maxWidth: labelMaxWidth, textColorAndFont: messageAttributes)
        return getBubbleSize(messageRow: messageRow, labelSize: labelSize, bubbleMargin: bubbleMargin, labelMargin: labelMargin)
    }
    
    public static func getContainerWidth(messageRow: TransactionMessageRow?) -> CGFloat {
        if messageRow?.isPodcastLive ?? false {
            return DashboardViewController.kPodcastPlayerWidth - 10
        }
        
        let incoming = messageRow?.isIncoming() ?? false
        
        if incoming {
            return MessageBubbleView.kBubbleReceivedMaxWidth
        } else {
            return MessageBubbleView.kBubbleSentMaxWidth
        }
    }
    
    func showIncomingMessageBubble(messageRow: TransactionMessageRow, minimumWidth: CGFloat = 0.0, chatWidth: CGFloat) -> (NSTextField, CGSize) {
        self.chatWidth = chatWidth
        
        let hasLinkPreview = messageRow.shouldShowLinkPreview() || messageRow.shouldShowTribeLinkPreview() || messageRow.shouldShowPubkeyPreview()
        let fixedWidth = hasLinkPreview ? MessageBubbleView.kBubbleLinkPreviewWidth : nil
        return showIncomingMessageBubble(messageRow: messageRow, fixedBubbleWidth: fixedWidth, minimumWidth: minimumWidth)
    }
    
    func showIncomingMessageBubble(messageRow: TransactionMessageRow, fixedBubbleWidth: CGFloat?, minimumWidth: CGFloat = 0.0) -> (NSTextField, CGSize) {
        self.messageRow = messageRow
        
        clearBubbleView()

        let containerWidth = fixedBubbleWidth ?? MessageBubbleView.getContainerWidth(messageRow: messageRow)
        let bubbleColors = getBubbleColors(messageRow: messageRow, incoming: true)
        let labelMargin = MessageBubbleView.getLabelMargin(messageRow: messageRow)
        let (label, labelSize, bubbleSize, bubbleMargin) = MessageBubbleView.getLabelAttributes(messageRow: messageRow, containerViewWidth: containerWidth, bubbleMargin: Constants.kBubbleReceivedArrowMargin, labelMargin: labelMargin)

        var bubbleWidth = fixedBubbleWidth ?? bubbleSize.width
        bubbleWidth = (minimumWidth > bubbleWidth) ? minimumWidth : bubbleWidth
        
        let linkPreviewHeight = CommonChatCollectionViewItem.getBubbleLinkPreviewHeight(messageRow: messageRow)
        let bubbleHeight = bubbleSize.height + linkPreviewHeight
        let size = CGSize(width: bubbleWidth, height: bubbleHeight)
        
        let messageBezierPath = getIncomingBezierPath(size: size, bubbleMargin: bubbleMargin, consecutiveBubbles: getConsecutiveBubble(messageRow: messageRow), consecutiveMessages: messageRow.getConsecutiveMessages())

        let comingMessageLayer = CAShapeLayer()
        comingMessageLayer.path = messageBezierPath.cgPath
        comingMessageLayer.frame = CGRect(x: 0,
                                          y: 0,
                                          width: size.width,
                                          height: size.height)
        comingMessageLayer.fillColor = bubbleColors.0
        comingMessageLayer.strokeColor = bubbleColors.1
        comingMessageLayer.lineWidth = 1
        comingMessageLayer.name = CommonBubbleView.kBubbleLayerName

        label.frame.origin.x = labelMargin + Constants.kBubbleReceivedArrowMargin
        label.frame.origin.y = labelMargin
        label.frame.size = labelSize
        label.layoutSubtreeIfNeeded()
        label.tag = MessageBubbleView.kMessageLabelTag

        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.layer?.addSublayer(comingMessageLayer)
        self.addMessageShadow(layer: comingMessageLayer)
        
        self.addSubview(label)
        
        return (label, size)
    }
    
    func showOutgoingMessageBubble(messageRow: TransactionMessageRow, minimumWidth: CGFloat = 0.0, topPadding: CGFloat = 0.0, chatWidth: CGFloat) -> (NSTextField, CGSize) {
        self.chatWidth = chatWidth
        
        let hasLinkPreview = messageRow.shouldShowLinkPreview() || messageRow.shouldShowTribeLinkPreview() || messageRow.shouldShowPubkeyPreview()
        let fixedWidth = hasLinkPreview ? MessageBubbleView.kBubbleLinkPreviewWidth : nil
        return showOutgoingMessageBubble(messageRow: messageRow, fixedBubbleWidth: fixedWidth, minimumWidth: minimumWidth, topPadding: topPadding)
    }
    
    func showOutgoingMessageBubble(messageRow: TransactionMessageRow, fixedBubbleWidth: CGFloat?, minimumWidth: CGFloat = 0.0, topPadding: CGFloat = 0.0) -> (NSTextField, CGSize)  {
        self.messageRow = messageRow
        
        clearBubbleView()

        let containerWidth = fixedBubbleWidth ?? MessageBubbleView.getContainerWidth(messageRow: messageRow)
        let bubbleColors = getBubbleColors(messageRow: messageRow, incoming: false)
        let labelMargin = MessageBubbleView.getLabelMargin(messageRow: messageRow)
        let (label, labelSize, bubbleSize, bubbleMargin) = MessageBubbleView.getLabelAttributes(messageRow: messageRow, containerViewWidth: containerWidth, labelMargin: labelMargin)
        
        var bubbleWidth =  fixedBubbleWidth ?? bubbleSize.width
        bubbleWidth = (minimumWidth > bubbleWidth) ? minimumWidth : bubbleWidth
        
        let linkPreviewHeight = CommonChatCollectionViewItem.getBubbleLinkPreviewHeight(messageRow: messageRow)
        let bubbleHeight = bubbleSize.height + linkPreviewHeight
        let size = CGSize(width: bubbleWidth, height: bubbleHeight + topPadding)
        let messageBezierPath = getOutgoingBezierPath(size: size, bubbleMargin: bubbleMargin, consecutiveBubbles: getConsecutiveBubble(messageRow: messageRow), consecutiveMessages: messageRow.getConsecutiveMessages())

        let outgoingMessageLayer = CAShapeLayer()
        outgoingMessageLayer.path = messageBezierPath.cgPath
        outgoingMessageLayer.frame = CGRect(x: 0,
                                            y: 0,
                                            width: size.width,
                                            height: size.height)

        outgoingMessageLayer.fillColor = bubbleColors.0
        outgoingMessageLayer.strokeColor = bubbleColors.1
        outgoingMessageLayer.lineWidth = 1
        outgoingMessageLayer.name = CommonBubbleView.kBubbleLayerName

        label.frame.origin.x = labelMargin
        label.frame.origin.y = labelMargin + topPadding
        label.frame.size = labelSize
        label.layoutSubtreeIfNeeded()
        label.tag = MessageBubbleView.kMessageLabelTag

        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.layer?.addSublayer(outgoingMessageLayer)
        self.addMessageShadow(layer: outgoingMessageLayer)
        self.addSubview(label)
        
        return (label, size)
    }
    
    func showIncomingMessageWebViewBubble(messageRow: TransactionMessageRow) -> CGSize {
        self.messageRow = messageRow

        clearBubbleView()

        let labelMargin = MessageBubbleView.getLabelMargin(messageRow: messageRow)
        let webViewHeight = messageRow.transactionMessage.getWebViewHeight() ?? MessageWebViewReceivedCollectionViewItem.kMessageWebViewRowHeight
        let bubbleWidth = MessageWebViewReceivedCollectionViewItem.kMessageWebViewBubbleWidth + (Constants.kLabelMargins * 2)
        let bubbleSize = CGSize(width: bubbleWidth, height: webViewHeight + (labelMargin * 2))
        let bubbleColors = getBubbleColors(messageRow: messageRow, incoming: true)
        let messageBezierPath = getIncomingBezierPath(size: bubbleSize,
                                                      bubbleMargin: Constants.kBubbleReceivedArrowMargin,
                                                      consecutiveBubbles: getConsecutiveBubble(messageRow: messageRow),
                                                      consecutiveMessages: messageRow.getConsecutiveMessages())

        let incomingMessageLayer = CAShapeLayer()
        incomingMessageLayer.path = messageBezierPath.cgPath
        incomingMessageLayer.frame = CGRect(x: 0,
                                          y: 0,
                                          width: bubbleSize.width,
                                          height: bubbleSize.height)

        incomingMessageLayer.fillColor = bubbleColors.0
        incomingMessageLayer.strokeColor = bubbleColors.1
        incomingMessageLayer.lineWidth = 1
        incomingMessageLayer.name = CommonBubbleView.kBubbleLayerName

        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.layer?.addSublayer(incomingMessageLayer)
        self.addMessageShadow(layer: incomingMessageLayer)

        return bubbleSize
    }
    
    func getConsecutiveBubble(messageRow: TransactionMessageRow) -> ConsecutiveBubbles {
        if messageRow.isPodcastLive {
            return ConsecutiveBubbles(previousBubble: false, nextBubble: false)
        }
        
        let isReply = messageRow.isReply
        let isPaidAttachment = messageRow.isPaidAttachment
        let isMediaAttachment = messageRow.isMediaAttachment
        let isPodcastComment = messageRow.isPodcastComment
        let hasLinkBubble = messageRow.shouldShowTribeLinkPreview() || messageRow.shouldShowPubkeyPreview()
        
        let previousBubble = isMediaAttachment || isReply || isPodcastComment
        
        if messageRow.isIncoming() {
            return ConsecutiveBubbles(previousBubble: previousBubble, nextBubble: isPaidAttachment || hasLinkBubble)
        } else {
            return ConsecutiveBubbles(previousBubble: previousBubble, nextBubble: hasLinkBubble)
        }
    }
}
