//
//  PaidMessageSentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PaidMessageReceivedCollectionViewItem: CommonPaidMessageCollectionViewItem {
    
    @IBOutlet weak var paidAttachmentView: PaidAttachmentView!
    @IBOutlet weak var paidAttachmentViewWidth: NSLayoutConstraint!
    @IBOutlet weak var bubbleViewWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        
        commonConfigurationForMessages()
        configurePayment(messageRow: messageRow)
        
        lockSign.stringValue = messageRow.transactionMessage.encrypted ? "lock" : ""

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configurePayment(messageRow: TransactionMessageRow) {
        var bubbleWidth = PaidMessageReceivedCollectionViewItem.getBubbleSize(messageRow: messageRow).width + 1
        CommonChatCollectionViewItem.applyMinimumWidthTo(width: &bubbleWidth, minimumWidth: Constants.kMinimumReceivedWidth)
        paidAttachmentViewWidth.constant = bubbleWidth
        paidAttachmentView.superview?.layoutSubtreeIfNeeded()
        paidAttachmentView.configure(messageRow: messageRow, delegate: self)
    }
    
    func setBubbleWidth(bubbleSize: CGSize) {
        bubbleViewWidthConstraint.constant = bubbleSize.width
        bubbleView.layoutSubtreeIfNeeded()
    }
    
    override func showBubble(messageRow: TransactionMessageRow, error: Bool = false, chatWidth: CGFloat) {
        super.showBubble(messageRow: messageRow, chatWidth: chatWidth)
        
        messageRow.transactionMessage.paidMessageError = error
        
        let (label, size) = bubbleView.showIncomingMessageBubble(messageRow: messageRow, minimumWidth: Constants.kMinimumReceivedWidth, chatWidth: chatWidth)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: size, incoming: true)
        setBubbleWidth(bubbleSize: size)
        addLinksOnLabel(label: label)
    }
    
    public static func getBubbleSize(messageRow: TransactionMessageRow) -> CGSize {
        let hasLinkPreview = messageRow.shouldShowLinkPreview() || messageRow.shouldShowTribeLinkPreview() || messageRow.shouldShowPubkeyPreview()
        let width = hasLinkPreview ? MessageBubbleView.kBubbleLinkPreviewWidth : MessageBubbleView.kBubbleReceivedMaxWidth
        var bubbleSize = MessageBubbleView.getBubbleSizeFrom(messageRow: messageRow, containerViewWidth: width, bubbleMargin: Constants.kBubbleReceivedArrowMargin)
        CommonChatCollectionViewItem.applyMinimumWidthTo(size: &bubbleSize, minimumWidth: Constants.kMinimumReceivedWidth)
        bubbleSize.width = hasLinkPreview ? MessageBubbleView.kBubbleLinkPreviewWidth : bubbleSize.width
        return bubbleSize
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow, chatWidth: CGFloat) -> CGFloat {
        let bubbleSize = PaidMessageReceivedCollectionViewItem.getBubbleSize(messageRow: messageRow)
        let replyTopPadding = CommonChatCollectionViewItem.getReplyTopPadding(message: messageRow.transactionMessage)
        let rowHeight = bubbleSize.height + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin + replyTopPadding
        let payButtonHeight: CGFloat = messageRow.shouldShowPaidAttachmentView() ? PaidAttachmentView.kViewHeight : 0.0
        let linksHeight = CommonChatCollectionViewItem.getLinkPreviewHeight(messageRow: messageRow)
        return rowHeight + linksHeight + payButtonHeight
    }
}

extension PaidMessageReceivedCollectionViewItem : PaidAttachmentViewDelegate {
    func didTapPayButton() {
        if let message = messageRow?.transactionMessage {
            let price = message.getAttachmentPrice() ?? 0
            paidAttachmentView.configure(status: TransactionMessage.TransactionMessageType.purchase, price: price)
            delegate?.didTapPayAttachment(transactionMessage: message)
        }
    }
}
