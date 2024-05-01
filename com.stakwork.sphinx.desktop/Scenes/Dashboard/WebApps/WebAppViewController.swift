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
    @IBOutlet weak var loadingView: NSImageView!
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    
    var webView: WKWebView!
    var gameURL: String! = nil
    var chat: Chat! = nil
    var finishLoadingTimer : Timer? = nil
    
    let webAppHelper = WebAppHelper()
    
    static func instantiate(chat: Chat, isAppURL: Bool = true) -> WebAppViewController? {
        let viewController = StoryboardScene.Dashboard.webAppViewController.instantiate()
        viewController.chat = chat
        
        guard let tribeInfo = chat.tribeInfo, let gameURL = isAppURL ? tribeInfo.appUrl : tribeInfo.secondBrainUrl, !gameURL.isEmpty else {
            return nil
        }
        
        viewController.gameURL = gameURL
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webAppHelper.delegate = self
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.Sphinx.Body.cgColor
        
        authorizeModalContainer.isHidden = true
        authorizeModalContainer.alphaValue = 0.0
        
        addWebView()
        loadPage()
    }
    
    func checkForLSAT(){
        webAppHelper.checkForExistingLsat(completion: { amount in
            print(amount ?? 0)
        })
    }
    
    @objc func showLsatList(){
        NewMessageBubbleHelper().showGenericMessageView(text: "Retrieving your L402s...", in: nil)
        
        webAppHelper.listLSats(completion: { success in
            if(success){
                let viewController = LsatListViewController.instantiate(lsatList: self.webAppHelper.lsatList)
                
                WindowsManager.sharedInstance.showNewWindow(
                    with: "my.lsats".localized,
                    size: CGSize(width: 480, height: 600),
                    centeredIn: self.view.window,
                    contentVC: viewController
                )
                print(self.webAppHelper.lsatList)
            }
            else{
                NewMessageBubbleHelper().showGenericMessageView(text: "Error loading L402 data please try again.", in: nil)
            }
        })
        
    }
    
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        view.window?.delegate = self
    }
    
    func addWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(webAppHelper, name: webAppHelper.messageHandler)
        configuration.preferences.setValue(true, forKey: "fullScreenEnabled")
        
        let rect = CGRect(x: 0, y: 0, width: 700, height: 500)
        webView = WKWebView(frame: rect, configuration: configuration)
        webView.customUserAgent = "Sphinx"
        webView.isHidden = true
        webView.navigationDelegate = self
        
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }
        
        webView.setBackgroundColor(color: NSColor.clear)
        addLoadingView()
        finishLoadingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(checkForWebViewDoneLoading), userInfo: nil, repeats: true)

        self.view.addSubview(webView, positioned: .below, relativeTo: authorizeModalContainer)
        addWebViewConstraints()

        webAppHelper.setWebView(webView, authorizeHandler: configureAuthorizeView, authorizeBudgetHandler: configureBudgetView)
    }
    
    func addLoadingView(){
        loadingView.isHidden = false
        loadingView.image = #imageLiteral(resourceName: "whiteIcon")
        loadingIndicator.startAnimation(self)
    }
    
    func removeLoadingView(){
        loadingView.isHidden = true
        loadingIndicator.isHidden = true
    }
    
    @objc func checkForWebViewDoneLoading(){
        if(webView.isLoading == false){
            finishLoadingTimer?.invalidate()
            webView.isHidden = false
            removeLoadingView()
        }
    }
    
    func configureAuthorizeView(_ dict: [String: AnyObject]) {
        let viewHeight = authorizeAppView.configureFor(url: gameURL, delegate: self, dict: dict, showBudgetField: false)
        authorizeAppViewHeight.constant = viewHeight
        authorizeAppView.layoutSubtreeIfNeeded()
        toggleAuthorizationView(show: true)
    }
    
    func configureBudgetView(_ dict: [String: AnyObject]) {
        let viewHeight = authorizeAppView.configureFor(url: gameURL, delegate: self, dict: dict, showBudgetField: true)
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
        
        if let tribeUUID = chat.tribeInfo?.uuid ?? chat.uuid {
            url = url.withURLParam(key: "uuid", value: tribeUUID)
        }
        
        if let host = chat.host {
            url = url.withURLParam(key: "host", value: host)
        }
        
        if let url = URL(string: url) {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
            webView.load(request)
        }
    }
}

extension WebAppViewController : WKNavigationDelegate {
     func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
         if navigationAction.navigationType == .linkActivated  {
             if let url = navigationAction.request.url, url.absoluteString.contains("open=system") {
                 NSWorkspace.shared.open(url)
                 decisionHandler(.cancel)
                 return
             } else {
                 decisionHandler(.allow)
                 return
             }
         } else {
             decisionHandler(.allow)
             return
         }
     }
 }

extension WebAppViewController : AuthorizeAppViewDelegate {
    func shouldCloseAuthorizeView() {
        toggleAuthorizationView(show: false)
    }
    
    func toggleAuthorizationView(show: Bool) {
        if show {
            authorizeModalContainer.isHidden = false
        }
        
        AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
            self.authorizeModalContainer.alphaValue = show ? 1.0 : 0.0
        }) {
            if !show {
                self.authorizeModalContainer.isHidden = true
            }
        }
    }
    
    func shouldAuthorizeBudgetWith(amount: Int, dict: [String : AnyObject]) {
        webAppHelper.authorizeWebApp(amount: amount, dict: dict, completion: {
            self.chat.updateWebAppLastDate()
            self.shouldCloseAuthorizeView()
        })
    }
    
    func shouldAuthorizeWith(dict: [String : AnyObject]) {
        webAppHelper.authorizeNoBudget(dict: dict, completion: {
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

extension WebAppViewController: WebAppHelperDelegate {
    func setBudget(budget: Int) {
        print(budget)
    }
}
