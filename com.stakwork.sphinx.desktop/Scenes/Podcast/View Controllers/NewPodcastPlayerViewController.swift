//
//  NewPodcastPlayerViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class NewPodcastPlayerViewController: NSViewController {
    
    weak var delegate: PodcastPlayerViewDelegate?
    
    @IBOutlet weak var playerCollectionView: NSCollectionView!
    
    var newEpisodeView: NewEpisodeAlertView? = nil
    
    var chat: Chat! = nil
    var collectionViewDS: PodcastEpisodesDataSource! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        showEpisodesTable()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        playerCollectionView.collectionViewLayout?.invalidateLayout()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: playerCollectionView.enclosingScrollView?.contentView,
            queue: OperationQueue.main
        ) { [weak self] (n: Notification) in
            
            self?.newEpisodeView?.hideView()
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: nil)
    }
    
    static func instantiate(chat: Chat, delegate: PodcastPlayerViewDelegate) -> NewPodcastPlayerViewController {
        let viewController = StoryboardScene.Podcast.newPodcastPlayerViewController.instantiate()
        viewController.chat = chat
        viewController.delegate = delegate
        
        return viewController
    }
    
    func showEpisodesTable() {
        guard let contentFeed = chat.contentFeed else {
            return
        }
        let podcast = PodcastFeed.convertFrom(contentFeed: contentFeed)
        
        collectionViewDS = PodcastEpisodesDataSource(
            collectionView: playerCollectionView,
            chat: chat,
            podcastFeed: podcast,
            delegate: self
        )
        
        newEpisodeView = NewEpisodeAlertView.checkForNewEpisode(
            podcast: podcast,
            view: self.view
        )
    }
}

extension NewPodcastPlayerViewController : PodcastEpisodesDSDelegate {    
    func shouldShareClip(comment: PodcastComment) {
        delegate?.shouldShareClip(comment: comment)
    }
    
    func shouldSendBoost(message: String, amount: Int, animation: Bool) -> TransactionMessage? {
        return delegate?.shouldSendBoost(message: message, amount: amount, animation: animation)
    }
}
