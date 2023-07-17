//
//  NewChatViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 07/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NewChatViewController: DashboardSplittedViewController {
    
    @IBOutlet weak var chatTopView: ChatTopView!
    @IBOutlet weak var chatBottomView: ChatBottomView!
    @IBOutlet weak var podcastPlayerView: NSView!
    
    @IBOutlet weak var mentionsScrollView: NSScrollView!
    @IBOutlet weak var mentionsCollectionView: NSCollectionView!
    @IBOutlet weak var mentionsScrollViewHeightConstraint: NSLayoutConstraint!
    
    var contact: UserContact?
    var chat: Chat?
    var deepLinkData : DeeplinkData? = nil
    
    var contactResultsController: NSFetchedResultsController<UserContact>!
    var chatResultsController: NSFetchedResultsController<Chat>!
    
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    var chatMentionAutocompleteDataSource : ChatMentionAutocompleteDataSource? = nil
    var podcastPlayerVC: NewPodcastPlayerViewController? = nil
    
    static func instantiate(
        contact: UserContact? = nil,
        chat: Chat? = nil,
        delegate: DashboardVCDelegate?,
        deepLinkData : DeeplinkData? = nil
    ) -> NewChatViewController {
        
        let viewController = StoryboardScene.Dashboard.newChatViewController.instantiate()
        
        viewController.chat = chat
        viewController.contact = contact
        viewController.delegate = delegate
        viewController.deepLinkData = deepLinkData
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupData()
        configureFetchResultsController()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        fetchTribeData()
        configureMentionAutocompleteTableView()
    }
    
    func setupData() {
        chatTopView.configureHeaderWith(
            chat: chat,
            contact: contact,
            andDelegate: self
        )
        
        configurePinnedMessageView()
        
        chatBottomView.updateFieldStateFrom(
            chat,
            and: contact,
            with: self
        )
        
        processChatAliases()
        
//        showPendingApprovalMessage()
    }
}
