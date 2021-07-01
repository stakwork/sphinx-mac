//
//  PaidMessageSentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PaidMessageSentCollectionViewItem: CommonPaidMessageCollectionViewItem {
    
    @IBOutlet weak var seenSign: NSTextField!
    @IBOutlet weak var attachmentPriceView: AttachmentPriceView!
    @IBOutlet weak var bubbleViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var errorSign: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configurePrice(messageRow: messageRow)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configurePrice(messageRow: TransactionMessageRow) {
        let price = messageRow.transactionMessage.getAttachmentPrice() ?? 0
        let statusAttributes = messageRow.transactionMessage.getPurchaseStatusLabel(queryDB: false)
        attachmentPriceView.configure(price: price, status: statusAttributes, forceShow: true)
    }
    
    override func showBubble(messageRow: TransactionMessageRow, error: Bool = false, chatWidth: CGFloat) {
        super.showBubble(messageRow: messageRow, chatWidth: chatWidth)
        
        let (label, size) = bubbleView.showOutgoingMessageBubble(messageRow: messageRow, minimumWidth: Constants.kMinimumSentWidth, topPadding: Constants.kPaidSentFixedTopPadding, chatWidth: chatWidth)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: size, incoming: false)
        setBubbleWidth(bubbleSize: size)
        addLinksOnLabel(label: label)
        
        configureMessageStatus()
    }
    
    func configureMessageStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        let received = messageRow.transactionMessage.received()
        let failed = messageRow.transactionMessage.failed()
        let encrypted = messageRow.encrypted
        
        seenSign.alphaValue = received ? 1.0 : 0.0
        lockSign.stringValue = (encrypted && !failed) ? "lock" : ""
        errorSign.alphaValue = failed ? 1.0 : 0.0
    }
    
    func setBubbleWidth(bubbleSize: CGSize) {
        bubbleViewWidthConstraint.constant = bubbleSize.width
        bubbleView.layoutSubtreeIfNeeded()
    }
    
    public static func getBubbleSize(messageRow: TransactionMessageRow) -> CGSize {
        let hasLinkPreview = messageRow.shouldShowLinkPreview() || messageRow.shouldShowTribeLinkPreview() || messageRow.shouldShowPubkeyPreview()
        let width = hasLinkPreview ? MessageBubbleView.kBubbleLinkPreviewWidth : MessageBubbleView.kBubbleSentMaxWidth
        var bubbleSize = MessageBubbleView.getBubbleSizeFrom(messageRow: messageRow, containerViewWidth: width)
        CommonChatCollectionViewItem.applyMinimumWidthTo(size: &bubbleSize, minimumWidth: Constants.kMinimumSentWidth)
        bubbleSize.width = hasLinkPreview ? MessageBubbleView.kBubbleLinkPreviewWidth : bubbleSize.width
        return bubbleSize
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow, chatWidth: CGFloat) -> CGFloat {
        let bubbleSize = getBubbleSize(messageRow: messageRow)
        let replyTopPadding = CommonChatCollectionViewItem.getReplyTopPadding(message: messageRow.transactionMessage)
        let rowHeight = bubbleSize.height + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin + Constants.kPaidSentFixedTopPadding + replyTopPadding
        let linksHeight = CommonChatCollectionViewItem.getLinkPreviewHeight(messageRow: messageRow)
        return rowHeight + linksHeight
    }
    
}
