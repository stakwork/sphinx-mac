//
//  MessageWebViewReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 17/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import WebKit

class MessageWebViewReceivedCollectionViewItem: CommonReplyCollectionViewItem {
    
    @IBOutlet weak var bubbleView: MessageBubbleView!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var bubbleWidth: NSLayoutConstraint!
    @IBOutlet weak var webView: BotWebView!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    @IBOutlet weak var webViewTopMargin: NSLayoutConstraint!
    @IBOutlet weak var webViewBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var webViewRightMargin: NSLayoutConstraint!
    @IBOutlet weak var webViewLeftMargin: NSLayoutConstraint!
    
    public static let kMessageWebViewRowHeight: CGFloat = 60
    public static let kMessageWebViewBubbleWidth: CGFloat = 220
    public static let kMessageWebViewMargin: CGFloat = 8
    
    let kWebViewContentPrefix = "<head><meta name=\"viewport\" content=\"width=device-width, height=device-height, shrink-to-fit=YES\"></head><body style=\"font-family: 'Roboto', sans-serif; color: %@; margin:0px !important; padding:0px!important; background: %@; overflow: hidden;\"><div id=\"bot-response-container\" style=\"background: %@;\">"
    let kWebViewContentSuffix = "</div></body>"
    
    let kDocumentReadyJSCommand = "document.readyState"
    let kGetContainerJSCommand = "document.getElementById(\"bot-response-container\").clientHeight"
    
    var loading = false {
        didSet {
            webView.alphaValue = loading ? 0.0 : 1.0
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [])
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loading = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        bubbleView.clearBubbleView()
        let _ = webView.loadHTMLString("", baseURL: Bundle.main.bundleURL)
        webView.stopLoading()
        webView.message = nil
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        
        let size = bubbleView.showIncomingMessageWebViewBubble(messageRow: messageRow)
        setBubbleWidth(bubbleSize: size)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: size, incoming: true)
        
        commonConfigurationForMessages()
        lockSign.stringValue = messageRow.transactionMessage.encrypted ? "lock" : ""

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
        
        setWebViewMargins()
        setWebViewContent()
    }
    
    func setBubbleWidth(bubbleSize: CGSize) {
        bubbleWidth.constant = bubbleSize.width
        bubbleView.layoutSubtreeIfNeeded()
    }
    
    func setWebViewMargins() {
        if webViewTopMargin.constant != Constants.kLabelMargins {
            webViewTopMargin.constant = Constants.kLabelMargins
            webViewBottomMargin.constant = Constants.kLabelMargins
            webViewRightMargin.constant = Constants.kLabelMargins
            webViewLeftMargin.constant = Constants.kLabelMargins + Constants.kBubbleReceivedArrowMargin
            webView.superview?.layoutSubtreeIfNeeded()
        }
    }
    
    func setWebViewContent() {
        webView.navigationDelegate = self
        webView.enclosingScrollView?.automaticallyAdjustsContentInsets = false
        webView.message = messageRow?.transactionMessage
        
        let backgroundColor = NSColor.Sphinx.OldReceivedMsgBG.toHexString()
        let textColor = NSColor.Sphinx.Text.toHexString()
        
        let contentPrefix = String(format: kWebViewContentPrefix, textColor, backgroundColor, backgroundColor)
        let messageContent = messageRow?.transactionMessage.messageContent ?? ""
        let content = "\(contentPrefix)\(messageContent)\(kWebViewContentSuffix)"
        
        let webViewHeight = messageRow?.transactionMessage.getWebViewHeight()
        if content != webView.contentString || webViewHeight == nil {
            loading = true
            let _ = webView.loadHTMLString(content, baseURL: Bundle.main.bundleURL)
        } else {
            hideLoadingWheel(withDelay: 0.2)
        }
    }
    
    func hideLoadingWheel(withDelay delay: Double) {
        DelayPerformedHelper.performAfterDelay(seconds: delay, completion: {
            self.loading = false
        })
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let webViewHeight = messageRow.transactionMessage.getWebViewHeight() ?? kMessageWebViewRowHeight
        let replyTopPadding = CommonChatCollectionViewItem.getReplyTopPadding(message: messageRow.transactionMessage)
        return webViewHeight + replyTopPadding + (Constants.kLabelMargins * 2) + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin
    }
}

extension MessageWebViewReceivedCollectionViewItem : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let webViewHeight = messageRow?.transactionMessage.getWebViewHeight() {
            self.webView.frame.size.height = webViewHeight
            
            hideLoadingWheel(withDelay: 0.2)
        } else {
            webView.evaluateJavaScript(self.kDocumentReadyJSCommand, completionHandler: { (complete, error) in
                if complete == nil {
                    return
                }
                
                webView.evaluateJavaScript(self.kGetContainerJSCommand, completionHandler: { (height, error) in
                    let height = ((height as? CGFloat) ?? MessageWebViewReceivedCollectionViewItem.kMessageWebViewRowHeight) + 10
                    self.messageRow?.transactionMessage.save(webViewHeight: height)
                    self.webView.frame.size.height = height
                    self.reloadRowOnLoadFinished()
                })
            })
        }
    }
    
    func reloadRowOnLoadFinished() {
        self.delegate?.shouldReload?(item: self)
    }
}
