//
//  ThreadsListViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol ThreadsListViewControllerDelegate : AnyObject {
    func didSelectThreadWith(uuid: String)
}

class ThreadsListViewController: NSViewController {
    
    @IBOutlet weak var shimmeringView: ThreadsListShimmeringView!
    @IBOutlet weak var threadsCollectionView: NSCollectionView!
    @IBOutlet weak var noResultsFoundLabel: NSTextField!
    
    weak var delegate: ThreadsListViewControllerDelegate?
    
    var threadsListDataSource: ThreadsListDataSource? = nil
    
    var chat: Chat?
    
    let windowsManager = WindowsManager.sharedInstance
    
    static func instantiate(
        chatId: Int,
        delegate: ThreadsListViewControllerDelegate?
    ) -> ThreadsListViewController {
        let viewController = StoryboardScene.Dashboard.threadsListViewController.instantiate()
        
        viewController.chat = Chat.getChatWith(id: chatId)
        viewController.delegate = delegate
        
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
        windowsManager.closeIfExists(identifier: "threads-list")

        delegate?.didSelectThreadWith(uuid: uuid)        
    }
    
    func shouldGoToAttachmentViewFor(messageId: Int, isPdf: Bool) {}
    
    func shouldGoToVideoPlayerFor(messageId: Int, with data: Data) {}
}
