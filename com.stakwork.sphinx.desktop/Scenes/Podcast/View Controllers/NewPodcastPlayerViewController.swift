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
    var playerHelper: PodcastPlayerHelper! = nil
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
        
        newEpisodeView = NewEpisodeAlertView.checkForNewEpisode(chat: chat, view: self.view)
        
        NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: playerCollectionView.enclosingScrollView?.contentView, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.newEpisodeView?.hideView()
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: nil)
    }
    
    static func instantiate(chat: Chat, playerHelper: PodcastPlayerHelper, delegate: PodcastPlayerViewDelegate) -> NewPodcastPlayerViewController {
        let viewController = StoryboardScene.Podcast.newPodcastPlayerViewController.instantiate()
        viewController.chat = chat
        viewController.delegate = delegate
        viewController.playerHelper = playerHelper
        
        return viewController
    }
    
    func showEpisodesTable() {
        collectionViewDS = PodcastEpisodesDataSource(collectionView: playerCollectionView,
                                                     chat: chat,
                                                     episodes: playerHelper.getEpisodes(),
                                                     playerHelper: playerHelper,
                                                     delegate: self)
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
