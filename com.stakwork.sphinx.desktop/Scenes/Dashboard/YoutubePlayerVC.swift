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
    let kSecondsPerPayment = 10
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
        detailsView.setBackgroundColor(color: NSColor.Sphinx.Body)
        detailsView.layer?.cornerRadius = 12.0
        boostButton.delegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
            self.view.bringSubviewToFront(self.detailsView)
            self.detailsView.bringSubviewToFront(self.boostButton)
            self.detailsView.bringSubviewToFront(self.satsStreamView)
        })
        setupFeedBoostHelper()
        loadPage()
        setupStremView()
        configureTimer()
    }
    
    func loadPage() {
        var url: String = "https://www.youtube.com/watch?v=Qw4xak-vFXE&pp=ygUPdGZ0YyBtYXJ0eSBiZW50" //tftc
        
        if let url = URL(string: url) {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
            ytWebView.load(request)
        }
    }
    
    func setupStremView(){
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
