//
//  MessageSentWithCodeCollectionViewItem.swift
//  Sphinx
//
//  Created by James Carucci on 3/13/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class MessageSentWithCodeCollectionViewItem: CommonReplyCollectionViewItem {
    
    @IBOutlet weak var errorContainer: NSView!
    @IBOutlet weak var errorMessageLabel: NSTextField!
    @IBOutlet weak var errorContainerRight: NSLayoutConstraint!
    @IBOutlet weak var bubbleView: MessageBubbleView!
    @IBOutlet weak var seenSign: NSTextField!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var bubbleViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackView: NSStackView!
    var codeViews : [CodeWebView] = []
    
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
        //let (label, size) = bubbleView.showOutgoingMessageBubble(messageRow: messageRow, minimumWidth: minimumWidth, chatWidth: chatWidth)
        //setBubbleWidth(bubbleSize: size)
        //addLinksOnLabel(label: label)
        
        commonConfigurationForMessages()
        configureMessageStatus()
        //configureReplyBubble(bubbleView: bubbleView, bubbleSize: size, incoming: false)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
        
        let content = messageRow.getMessageContent()
        let components = content.components(separatedBy: "```")
        print(components)
        for i in 0..<components.count{
            if(i % 2 == 1){
                let codeView = CodeWebView(frame: CGRect(x: 0.0, y: 0.0, width: stackView.frame.width, height: MessageSentWithCodeCollectionViewItem.getRowHeight(messageRow: messageRow)))
                codeView.loadHTMLString(components[i], baseURL: nil)
                stackView.addView(codeView, in: .top)
                codeViews.append(codeView)
            }
        }
        self.view.bringSubviewToFront(stackView)
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
        errorContainer.alphaValue = failed ? 1.0 : 0.0
        errorContainer.layoutSubtreeIfNeeded()
        
        let bubbleSize = MessageSentCollectionViewItem.getBubbleSize(messageRow: messageRow)
        let rightConstraint = bubbleSize.width + MessageBubbleView.kBubbleSentRightMargin - errorContainer.frame.width
        errorMessageLabel.alphaValue = rightConstraint < 60 ? 0.0 : 1.0
        errorContainerRight.constant = rightConstraint
        errorContainer.superview?.layoutSubtreeIfNeeded()
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
        let labelMargin = MessageBubbleView.getLabelMargin(messageRow: messageRow)
        var bubbleSize = MessageBubbleView.getBubbleSizeFrom(messageRow: messageRow, containerViewWidth: width, labelMargin: labelMargin)
        let minimumWidth:CGFloat = CommonChatCollectionViewItem.getMinimumWidth(message: messageRow.transactionMessage)
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
