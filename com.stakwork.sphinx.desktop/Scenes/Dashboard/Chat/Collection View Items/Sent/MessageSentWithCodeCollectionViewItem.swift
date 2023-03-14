//
//  MessageSentWithCodeCollectionViewItem.swift
//  Sphinx
//
//  Created by James Carucci on 3/13/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import Down
import WebKit

class MessageSentWithCodeCollectionViewItem: CommonReplyCollectionViewItem {
    
    @IBOutlet weak var errorContainer: NSView!
    @IBOutlet weak var errorMessageLabel: NSTextField!
    @IBOutlet weak var errorContainerRight: NSLayoutConstraint!
    @IBOutlet weak var bubbleView: MessageBubbleView!
    @IBOutlet weak var seenSign: NSTextField!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var bubbleViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var markupContainerView: NSView!
    
    
    var codeViews : [CodeWebView] = []
    let codeTopBottomPadding = 50.0
    
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
        do{

            let dv = try DownView(frame: self.markupContainerView.bounds, markdownString: content,templateBundle: nil)
            dv.navigationDelegate = self
            markupContainerView.addSubview(dv)
        }
        catch let error{
            print(error)
        }
        
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
        return (rowHeight + linksHeight)
    }
}

extension MessageSentWithCodeCollectionViewItem : WKNavigationDelegate{
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.innerHTML") {(result, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            print(String(describing: result))
        }
        
        let fontChangeJS = """
        paragraphs = document.querySelectorAll('.hljs');
          paragraphs.forEach((p) => {
            p.style.fontSize = "14px" ;
          })
        """
        
        webView.evaluateJavaScript(fontChangeJS) {(result, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            print(String(describing: result))
        }
    }
}

extension String {
    
    func numberOfLines() -> Int {
        return self.numberOfOccurrencesOf(string: "\n") + 1
    }

    func numberOfOccurrencesOf(string: String) -> Int {
        return self.components(separatedBy:string).count - 1
    }
    
    func slice(from: String, to: String) -> String? {
            return (range(of: from)?.upperBound).flatMap { substringFrom in
                (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                    String(self[substringFrom..<substringTo])
                }
            }
        }
}
