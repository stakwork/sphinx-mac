//
//  YoutubePlayerVC.swift
//  Sphinx
//
//  Created by James Carucci on 4/18/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import Cocoa
import WebKit

class YoutubePlayerVC : NSViewController{
    
    @IBOutlet weak var ytWebView: WKWebView!
    @IBOutlet weak var detailsView: NSView!
    @IBOutlet weak var boostViewContainer: NSView!
    @IBOutlet weak var boostButton: BoostButtonView!
    @IBOutlet weak var satsStreamView: PodcastSatsView!
    @IBOutlet weak var episodeTitleLabel: NSTextField!
    @IBOutlet weak var titleView: NSView!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var contributeLabel: NSTextField!
    
    let kSecondsPerPayment = 600
    var isPlaying : Bool = true
    var playedSeconds : Int = 0
    var fbh = FeedBoostHelper()
    
    var viewItem : ContentFeedItem? = ContentFeedItem.getItemWith(itemID: "14937084479")
    var paymentsTimer : Timer? = nil
    
    static func instantiate() -> YoutubePlayerVC {
        let viewController = StoryboardScene.Dashboard.youtubeViewController.instantiate()
        
        return viewController
    }
    
    
    override func viewDidLoad() {
        self.view.setBackgroundColor(color: NSColor.Sphinx.Body)
        detailsView.setBackgroundColor(color: NSColor.Sphinx.Body)
        detailsView.layer?.cornerRadius = 12.0
        boostButton.delegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
            self.view.bringSubviewToFront(self.detailsView)
            self.detailsView.bringSubviewToFront(self.boostButton)
            self.detailsView.bringSubviewToFront(self.satsStreamView)
            self.detailsView.bringSubviewToFront(self.titleView)
            self.view.bringSubviewToFront(self.contributeLabel)
            self.titleView.bringSubviewToFront(self.episodeTitleLabel)
            self.titleView.bringSubviewToFront(self.descriptionLabel)
        })
        setupFeedBoostHelper()
        setupStreamView()
        configureTimer()
        searchTest()
    }
    
    override func viewWillDisappear() {
        paymentsTimer?.invalidate()
        paymentsTimer = nil
    }
    
    func loadPage(url:URL) {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
        ytWebView.load(request)
    }
    
    func loadPage(itemID:String) {
        let heightString = String(self.view.frame.height - detailsView.frame.height - 50.0)
        let iframe = """
        <html><body><iframe width="100%" height="\(heightString)" src="https://www.youtube.com/embed/\(itemID)" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen; allowscriptaccess="always";></iframe></body></html>
        """
        let embededHTML = iframe
        self.ytWebView.loadHTMLString(embededHTML, baseURL: Bundle.main.bundleURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0, execute: {
            self.debugWebview()
        })
    }
    
    func debugWebview(){
        ytWebView.evaluateJavaScript("document.documentElement.outerHTML") { (html, error) in
            guard let html = html as? String else {
                print(error)
                return
            }
            // Here you have HTML of the whole page.
            print(html)
        }
        
        let stopCommand = """
            $('.yt_player_iframe').each(function(){
              this.contentWindow.postMessage('{"event":"command","func":"stopVideo","args":""}', '*')
            });
        """
        ytWebView.evaluateJavaScript(stopCommand)
    }
    
    func setupStreamView(){
        if let item = viewItem,
           let feed = item.contentFeed,
           let chat = feed.chat{
            satsStreamView.configureWith(chat: chat)
            //satsStreamView.setBackgroundColor(color: NSColor.purple)
            for view in satsStreamView.subviews{
                satsStreamView.bringSubviewToFront(view)
            }
        }
    }
    
    func configureTimer() {
        paymentsTimer?.invalidate()
        paymentsTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(updatePlayedTime),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc func updatePlayedTime(){
        //TODO: only run this if YT is actually playing
        self.playedSeconds = self.playedSeconds + ((isPlaying) ? 1 : 0)
        if self.playedSeconds > 0 && self.playedSeconds % self.kSecondsPerPayment == 0 {
            DispatchQueue.global().async {
                self.processPayment()
            }
        }
    }
    
    func setupFeedBoostHelper(){
        if let item = viewItem,
           let feed = item.contentFeed{
            fbh.configure(with: feed.objectID, and: feed.chat)
        }
    }
    
    
    func processPayment(){
        if let item = viewItem,
           let feed = item.contentFeed{
            let pf = PodcastFeed.convertFrom(contentFeed: feed)
            fbh.processPayment(itemID: item.id, amount: pf.satsPerMinute ?? 0)
        }
    }
    
    func configureUI(item:ContentFeedItem){
        episodeTitleLabel.usesSingleLineMode = false
        episodeTitleLabel.cell?.wraps = true
        episodeTitleLabel.cell?.isScrollable = false
        episodeTitleLabel.stringValue = item.title
        
        descriptionLabel.usesSingleLineMode = false
        descriptionLabel.cell?.wraps = true
        descriptionLabel.cell?.isScrollable = false
        descriptionLabel.stringValue = item.itemDescription ?? ""
    }
    
    func fetchCFTest(searchResult:FeedSearchResult){
        ContentFeed.fetchContentFeed(
            at: searchResult.feedURLPath,
            chat: nil,
            searchResultDescription: searchResult.feedDescription,
            searchResultImageUrl: searchResult.imageUrl,
            persistingIn: CoreDataManager.sharedManager.getBackgroundContext(),
            then: { result in
                print(result)
                if case .success(let contentFeed) = result {
                    if #available(macOS 13.0, *) {
                        if let firstItem = contentFeed.items?.first,
                           let split = firstItem.linkURL?.absoluteString.split(separator: "v="),
                           split.count > 1{
                            let videoID = split[1]
                            self.loadPage(itemID: String(videoID))
                            self.configureUI(item: firstItem)
                        }
                    } else if let link = contentFeed.linkURL {
                        self.loadPage(url: link)
                        // Fallback on earlier versions
                    }
                    return
                }
                
        })
    }
    
    func searchTest(){
        API.sharedInstance.searchForFeeds(
            with: .Video,
            matching: "Tales from the Crypt Marty Bent"
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let results):
                    
                    if let firstResult = results.first{
                        print(firstResult)
                        self.fetchCFTest(searchResult: firstResult)
                    }
                    
                case .failure(_):
                    break
                }
            }
        }
    }
}

extension YoutubePlayerVC : BoostButtonViewDelegate{
    func didTouchButton() {
        print("Button pressed!")
        if let item = viewItem{
            //fbh.configure(with: feed.objectID, and: feed.chat)
            fbh.sendBoostMessage(message: "", itemObjectID: item.objectID, amount: 69, completion: {_,_ in 
                print("woohoo")
            })
        }
    }
}
