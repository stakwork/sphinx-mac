//
//  BotResponseView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import WebKit

class BotResponseView: NSView, LoadableNib {

    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var webView: BotWebView!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    let kWebViewContentPrefix = "<head><meta name=\"viewport\" content=\"width=device-width, height=device-height, shrink-to-fit=YES\"></head><body style=\"font-family: 'Roboto', sans-serif; color: %@; margin:0px !important; padding:0px!important; background: %@;\"><div id=\"bot-response-container\" style=\"background: %@;\">"
    let kWebViewContentSuffix = "</div></body>"
    
    let kDocumentReadyJSCommand = "document.readyState"
    let kGetContainerJSCommand = "document.getElementById(\"bot-response-container\").clientHeight"
    
    static let kViewHeight: CGFloat = 78

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setup()
    }
    
    func releaseMemory() {
        webView = nil
    }
    
    deinit {
        webView = nil
    }
    
    func setup() {}
    
    func configureWith(
        botHTMLContent: BubbleMessageLayoutState.BotHTMLContent,
        botWebViewData: MessageTableCellState.BotWebViewData?
    ) {
        let loading = botWebViewData == nil
        
        loadingWheel.isHidden = !loading
        webView.isHidden = loading
        
        if !loading {
            loadingWheel.stopAnimation(nil)
            loadingWheel.isHidden = true
            
            let backgroundColor = NSColor(cgColor: NSColor.Sphinx.ReceivedMsgBG.cgColor)?.toHexString() ?? ""
            let textColor = NSColor(cgColor: NSColor.Sphinx.Text.cgColor)?.toHexString() ?? ""
            
            let contentPrefix = String(format: kWebViewContentPrefix, textColor, backgroundColor, backgroundColor)
            let messageContent = botHTMLContent.html
            let content = "\(contentPrefix)\(messageContent)\(kWebViewContentSuffix)"
            
            let _ = webView.loadHTMLString(content, messageId: botHTMLContent.messageId, baseURL: Bundle.main.bundleURL)
        } else {
            loadingWheel.startAnimation(nil)
            loadingWheel.isHidden = false
        }
    }
    
}
