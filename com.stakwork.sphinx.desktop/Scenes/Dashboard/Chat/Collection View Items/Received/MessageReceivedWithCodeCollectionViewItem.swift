//
//  MessageReceivedWithCodeCollectionViewItem.swift
//  Sphinx
//
//  Created by James Carucci on 3/15/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import Down
import WebKit

class MessageReceivedWithCodeCollectionViewItem:  CommonReplyCollectionViewItem {
    
    @IBOutlet weak var bubbleView: MessageBubbleView!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var bubbleViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var markupContainerView: NSView!
    
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
        
        commonConfigurationForMessages()
        
        lockSign.stringValue = messageRow.transactionMessage.encrypted ? "lock" : ""

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
        
        let content = messageRow.getMessageContent()
        do{

            let dv = try DownView(frame: self.markupContainerView.bounds, markdownString: content,templateBundle: nil)
            if let bubbleRadius = bubbleView.layer?.cornerRadius{
                dv.layer?.cornerRadius = bubbleRadius
                markupContainerView.layer?.cornerRadius = bubbleRadius
            }
            for view in dv.subviews{
                if let valid_view = view as? NSView,
                   let bubbleRadius = bubbleView.layer?.cornerRadius{
                    valid_view.setBackgroundColor(color: NSColor.clear)
                    valid_view.layer?.cornerRadius = bubbleRadius
                }
            }
            dv.navigationDelegate = self
            markupContainerView.addSubview(dv)
        }
        catch let error{
            print(error)
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

extension MessageReceivedWithCodeCollectionViewItem : WKNavigationDelegate{
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //printWebViewHTML(webView: webView)//for debug
        styleView(webView: webView, fontSize: "14", fontColor: "#FFFFFF", bubbleColor: "#222E3A")
    }
    
    func printWebViewHTML(webView:WKWebView){
        webView.evaluateJavaScript("document.body.innerHTML") {(result, error) in
            guard error == nil else {
                print(error!)
                return
            }
            
            print(String(describing: result))
        }
    }
    
    func styleView(webView:WKWebView,fontSize:String,fontColor:String,bubbleColor:String){
        let fontChangeJS = """
        code = document.querySelectorAll('.hljs');
          code.forEach((p) => {
            p.style.fontSize = "14px" ;
          });
        paragraphs = document.querySelectorAll('p');
          paragraphs.forEach((p) => {
            p.style.fontSize = "\(fontSize)px" ;
            p.style.color = "\(fontColor)";
          })
        document.body.style.backgroundColor = "\(bubbleColor)";
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
