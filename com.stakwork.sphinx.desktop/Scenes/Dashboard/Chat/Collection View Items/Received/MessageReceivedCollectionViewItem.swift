//
//  MessageReceivedCollectionViewItem.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 18/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class MessageReceivedCollectionViewItem: CommonReplyCollectionViewItem {
    
    @IBOutlet weak var bubbleView: MessageBubbleView!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var bubbleViewWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bubbleView.clearBubbleView()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        
        let minimumWidth:CGFloat = CommonChatCollectionViewItem.getMinimumWidth(message: messageRow.transactionMessage)
        let (label, size) = bubbleView.showIncomingMessageBubble(messageRow: messageRow, minimumWidth: minimumWidth, chatWidth: chatWidth)
        setBubbleWidth(bubbleSize: size)
        addLinksOnLabel(label: label)
        
        commonConfigurationForMessages()
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: size, incoming: true)
        
        lockSign.stringValue = messageRow.transactionMessage.encrypted ? "lock" : ""

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    override func getBubbbleView() -> NSView? {
        return bubbleView
    }
    
    func setBubbleWidth(bubbleSize: CGSize) {
        bubbleViewWidthConstraint.constant = bubbleSize.width
        bubbleView.layoutSubtreeIfNeeded()
    }
    
    public static func getBubbleSize(messageRow: TransactionMessageRow) -> CGSize {
        let hasLinkPreview = messageRow.shouldShowLinkPreview() || messageRow.shouldShowTribeLinkPreview() || messageRow.shouldShowPubkeyPreview()
        let width = hasLinkPreview ? MessageBubbleView.kBubbleLinkPreviewWidth : MessageBubbleView.getContainerWidth(messageRow: messageRow)
        let minimumWidth:CGFloat = CommonChatCollectionViewItem.getMinimumWidth(message: messageRow.transactionMessage)
        let labelMargin = MessageBubbleView.getLabelMargin(messageRow: messageRow)
        var bubbleSize = MessageBubbleView.getBubbleSizeFrom(messageRow: messageRow, containerViewWidth: width, bubbleMargin: Constants.kBubbleReceivedArrowMargin, labelMargin: labelMargin)
        CommonChatCollectionViewItem.applyMinimumWidthTo(size: &bubbleSize, minimumWidth: minimumWidth)
        return bubbleSize
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let bubbleSize = getBubbleSize(messageRow: messageRow)
        let replyTopPadding = CommonChatCollectionViewItem.getReplyTopPadding(message: messageRow.transactionMessage)
        let rowHeight = bubbleSize.height + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin + replyTopPadding
        let linksHeight = CommonChatCollectionViewItem.getLinkPreviewHeight(messageRow: messageRow)
        return rowHeight + linksHeight
    }
}
