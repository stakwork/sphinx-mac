//
//  ThreadsListViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ThreadsListViewController: NSViewController {
    
    @IBOutlet weak var shimmeringView: ThreadsListShimmeringView!
    @IBOutlet weak var threadsCollectionView: NSCollectionView!
    @IBOutlet weak var noResultsFoundLabel: NSTextField!
    
    var threadsListDataSource: ThreadsListDataSource? = nil
    
    var chat: Chat?
    var windowSize: CGSize? = nil
    
    let windowsManager = WindowsManager.sharedInstance
    
    static func instantiate(
        chatId: Int,
        windowSize: CGSize?
    ) -> ThreadsListViewController {
        let viewController = StoryboardScene.Dashboard.threadsListViewController.instantiate()
        
        viewController.chat = Chat.getChatWith(id: chatId)
        viewController.windowSize = windowSize
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        configureTableView()
    }
    
    func setupViews() {
        shimmeringView.isHidden = false
        shimmeringView.startAnimating()
        
        shimmeringView.isHidden = true
        shimmeringView.alphaValue = 0.0
    }
    
    func configureTableView() {
        guard let chat = chat else {
            return
        }
        
        threadsListDataSource = ThreadsListDataSource(
            chat: chat,
            collectionView: threadsCollectionView,
            noResultsFoundLabel: noResultsFoundLabel,
            shimmeringView: shimmeringView,
            delegate: self
        )
    }
}

extension ThreadsListViewController : ThreadsListDataSourceDelegate {
    func didSelectThreadWith(uuid: String) {
        let chatVC = NewChatViewController.instantiate(
            chatId: self.chat?.id,
            threadUUID: uuid
        )
        windowsManager.closeIfExists(identifier: "threads-list")
        windowsManager.showNewWindow(
            with: "thread-chat".localized,
            size: windowSize ?? CGSize(width: 800, height: 600),
            centeredIn: self.view.window,
            contentVC: chatVC
        )
    }
    
    func shouldGoToAttachmentViewFor(messageId: Int, isPdf: Bool) {}
    
    func shouldGoToVideoPlayerFor(messageId: Int, with data: Data) {}
}
