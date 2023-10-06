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
    @IBOutlet weak var threadHeaderView: ThreadHeaderView!
    @IBOutlet weak var chatBottomView: ChatBottomView!
    @IBOutlet weak var chatScrollView: NSScrollView!
    @IBOutlet weak var chatCollectionView: NSCollectionView!
    @IBOutlet weak var botWebView: WKWebView!
    @IBOutlet weak var draggingView: DraggingDestinationView!
    
    @IBOutlet weak var mentionsScrollView: NSScrollView!
    @IBOutlet weak var mentionsCollectionView: NSCollectionView!
    @IBOutlet weak var mentionsScrollViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var childViewControllerContainer: ChildVCContainer!
    @IBOutlet weak var pinMessageDetailView: PinMessageDetailView!
    @IBOutlet weak var pinMessageNotificationView: PinNotificationView!
    
    @IBOutlet weak var newMsgsIndicatorView: NewMessagesIndicatorView!
    
    var mediaFullScreenView: MediaFullScreenView? = nil
    
    var newChatViewModel: NewChatViewModel!
    
    var contact: UserContact?
    var tribeAdmin: UserContact?
    var chat: Chat?
    var owner: UserContact!
    var deepLinkData : DeeplinkData? = nil
    
    var threadUUID: String? = nil
    
    var isThread: Bool {
        get {
            return threadUUID != nil
        }
    }
    
    enum ViewMode: Int {
        case Standard
        case Search
    }
    
    var viewMode = ViewMode.Standard
    
    var contactResultsController: NSFetchedResultsController<UserContact>!
    var chatResultsController: NSFetchedResultsController<Chat>!
    
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    var chatTableDataSource: NewChatTableDataSource? = nil
    var chatMentionAutocompleteDataSource : ChatMentionAutocompleteDataSource? = nil
    var podcastPlayerVC: NewPodcastPlayerViewController? = nil
    
    static func instantiate(
        contactId: Int? = nil,
        chatId: Int? = nil,
        delegate: DashboardVCDelegate? = nil,
        deepLinkData : DeeplinkData? = nil,
        threadUUID: String? = nil
    ) -> NewChatViewController {
        
        let viewController = StoryboardScene.Dashboard.newChatViewController.instantiate()
        
        let owner = UserContact.getOwner()
        
        if let chatId = chatId {
            let chat = Chat.getChatWith(id: chatId)
            viewController.chat = chat
            viewController.tribeAdmin = chat?.getAdmin() ?? owner
        }
        
        if let contactId = contactId {
            viewController.contact = UserContact.getContactWith(id: contactId)
        }
        
        viewController.delegate = delegate
        viewController.deepLinkData = deepLinkData
        viewController.owner = owner
        viewController.threadUUID = threadUUID
        
        viewController.newChatViewModel = NewChatViewModel(
            chat: viewController.chat,
            contact: viewController.contact,
            threadUUID: threadUUID
        )
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addShimmeringView()
        setupViews()
        configureCollectionView()
        setupChatTopView()
        setupChatData()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        setupChatBottomView()
        fetchTribeData()
        configureMentionAutocompleteTableView()
        configureFetchResultsController()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        chatTableDataSource?.saveSnapshotCurrentState()
    }
    
    override func viewDidLayout() {
        chatTableDataSource?.updateFrame()
    }
    
    func forceReload() {
        chatTableDataSource?.forceReload()
    }
    
    func resetVC() {
        stopPlayingClip()
        resetFetchedResultsControllers()
        
        if let podcastPlayerVC = podcastPlayerVC {
            self.removeChildVC(child: podcastPlayerVC)
        }
        
        childViewControllerContainer.removeChildVC()
        
        chatTableDataSource?.stopListeningToResultsController()
    }
    
    func stopPlayingClip() {
        let podcastPlayerController = PodcastPlayerController.sharedInstance
        podcastPlayerController.removeFromDelegatesWith(key: PodcastDelegateKeys.ChatDataSource.rawValue)
        podcastPlayerController.pausePlayingClip()
    }
    
    func addShimmeringView() {
        if chat != nil || contact != nil {
            shimmeringView.toggle(show: true)
        }
    }
    
    func setupViews() {
        draggingView.setup()
    }
    
    func setupChatTopView() {
        if isThread {
            setupThreadHeaderView()
            
            chatTopView.isHidden = true
            threadHeaderView.isHidden = false
        } else {
            chatTopView.configureHeaderWith(
                chat: chat,
                contact: contact,
                andDelegate: self,
                searchDelegate: self
            )
            
            configurePinnedMessageView()
            
            chatTopView.isHidden = false
            threadHeaderView.isHidden = true
        }
    }
    
    func setupThreadHeaderView() {
        guard let tribeAdmin = tribeAdmin, let chatTableDataSource = chatTableDataSource else {
            return
        }
        
        if let messageStateAndMediaData = chatTableDataSource.getThreadOriginalMessageStateAndMediaData(
            owner: owner,
            tribeAdmin: tribeAdmin
        ) {
            threadHeaderView.configureWith(
                messageCellState: messageStateAndMediaData.0,
                mediaData: messageStateAndMediaData.1,
                delegate: chatTableDataSource
            )
        }
    }
    
    func setupChatBottomView() {
        chatBottomView.updateFieldStateFrom(
            chat,
            contact: contact,
            isThread: isThread,
            with: self,
            and: self
        )        
    }
    
    func setupChatData() {
        processChatAliases()
        showPendingApprovalMessage()
    }
    
    func showThread(
        threadID: String
    ){
        let chatVC = NewChatViewController.instantiate(
            contactId: self.contact?.id,
            chatId: self.chat?.id,
            delegate: delegate,
            threadUUID: threadID
        )
        
        var size = CGSize(width: 800, height: 600)
        
        if let currentWindowSize = self.view.window?.frame.size {
            size = CGSize(width: currentWindowSize.width * 0.9, height: currentWindowSize.height * 0.9)
        }
      
        WindowsManager.sharedInstance.showNewWindow(
            with: "thread-chat".localized,
            size: size,
            centeredIn: self.view.window,
            contentVC: chatVC
        )
    }
}
