//
//  WebGameViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import WebKit

class WebAppViewController: NSViewController {
    
    @IBOutlet weak var authorizeModalContainer: NSView!
    @IBOutlet weak var authorizeAppView: AuthorizeAppView!
    @IBOutlet weak var authorizeAppViewHeight: NSLayoutConstraint!
    
    var webView: WKWebView!
    var gameURL: String! = nil
    var chat: Chat! = nil
    
    let webAppHelper = WebAppHelper()
    
    static func instantiate(chat: Chat) -> WebAppViewController {
        let viewController = StoryboardScene.Dashboard.webAppViewController.instantiate()
        viewController.chat = chat
        
        if let tribeInfo = chat.tribeInfo, let gameURL = tribeInfo.appUrl, !gameURL.isEmpty {
            viewController.gameURL = gameURL
        }
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.Sphinx.Body.cgColor
        authorizeModalContainer.alphaValue = 0.0
        
        addWebView()
        loadPage()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        view.window?.delegate = self
    }
    
    func addWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(webAppHelper, name: webAppHelper.messageHandler)
        
        let rect = CGRect(x: 0, y: 0, width: 700, height: 500)
        webView = WKWebView(frame: rect, configuration: configuration)
        webView.customUserAgent = "Sphinx"

        self.view.addSubview(webView, positioned: .below, relativeTo: authorizeModalContainer)
        addWebViewConstraints()

        webAppHelper.setWebView(webView, authorizeHandler: configureAuthorizeView)
    }
    
    func configureAuthorizeView(_ dict: [String: AnyObject]) {
        let viewHeight = authorizeAppView.configureFor(url: gameURL, delegate: self, dict: dict)
        authorizeAppViewHeight.constant = viewHeight
        authorizeAppView.layoutSubtreeIfNeeded()
        toggleAuthorizationView(show: true)
    }
    
    func addWebViewConstraints() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: webView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: webView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: webView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self.view, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: webView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0.0).isActive = true
    }
    
    func loadPage() {
        var url: String = gameURL
        
        if let tribeUUID = chat.tribeInfo?.uuid {
            url = gameURL.withURLParam(key: "tribe", value: tribeUUID)
        }
        
        if let url = URL(string: url) {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
            webView.load(request)
        }
    }
}

extension WebAppViewController : AuthorizeAppViewDelegate {
    func shouldCloseAuthorizeView() {
        toggleAuthorizationView(show: false)
    }
    
    func toggleAuthorizationView(show: Bool) {
        AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
            self.authorizeModalContainer.alphaValue = show ? 1.0 : 0.0
        })
    }
    
    func shouldAuthorizeWith(amount: Int, dict: [String: AnyObject]) {
        webAppHelper.authorizeWebApp(amount: amount, dict: dict, completion: {
            self.chat.updateWebAppLastDate()
            self.shouldCloseAuthorizeView()
        })
    }
}

extension WebAppViewController : NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        webView.configuration.userContentController.removeAllUserScripts()
        webView.loadHTMLString("", baseURL: Bundle.main.bundleURL)
    }
}
