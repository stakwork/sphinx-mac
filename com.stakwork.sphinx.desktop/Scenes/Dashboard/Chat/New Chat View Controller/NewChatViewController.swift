//
//  NewChatViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 07/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import WebKit

class NewChatViewController: DashboardSplittedViewController {
    
    @IBOutlet weak var podcastPlayerView: NSView!
    @IBOutlet weak var shimmeringView: ChatShimmeringView!
    
    @IBOutlet weak var chatTopView: ChatTopView!
    @IBOutlet weak var chatBottomView: ChatBottomView!
    @IBOutlet weak var chatScrollView: NSScrollView!
    @IBOutlet weak var chatCollectionView: NSCollectionView!
    @IBOutlet weak var botWebView: WKWebView!
    
    @IBOutlet weak var mentionsScrollView: NSScrollView!
    @IBOutlet weak var mentionsCollectionView: NSCollectionView!
    @IBOutlet weak var mentionsScrollViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var childViewControllerContainer: ChildVCContainer!
    @IBOutlet weak var pinMessageDetailView: PinMessageDetailView!
    @IBOutlet weak var pinMessageNotificationView: PinNotificationView!
    
    var contact: UserContact?
    var chat: Chat?
    var deepLinkData : DeeplinkData? = nil
    
    var contactResultsController: NSFetchedResultsController<UserContact>!
    var chatResultsController: NSFetchedResultsController<Chat>!
    
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    var chatTableDataSource: NewChatTableDataSource? = nil
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

        addShimmeringView()
        setupData()
        configureFetchResultsController()
        configureCollectionView()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        fetchTribeData()
        configureMentionAutocompleteTableView()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        chatTableDataSource?.saveSnapshotCurrentState()
    }
    
    override func viewDidLayout() {
        chatTableDataSource?.updateFrame()
    }
    
    func resetVC() {
        stopPlayingClip()
    }
    
    func stopPlayingClip() {
        let podcastPlayerController = PodcastPlayerController.sharedInstance
        podcastPlayerController.removeFromDelegatesWith(key: PodcastDelegateKeys.ChatDataSource.rawValue)
        podcastPlayerController.pausePlayingClip()
    }
    
    func addShimmeringView() {
        if chat != nil || contact != nil {
            shimmeringView.isHidden = false
            shimmeringView.alphaValue = 0.15
            shimmeringView.startAnimating()
        }
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
