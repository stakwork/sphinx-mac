//
//  NewChatViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 07/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import WebKit

protocol NewChatViewControllerDelegate: AnyObject {
    func shouldResetOngoingMessage()
    func shouldCloseThread()
}

class NewChatViewController: DashboardSplittedViewController {
    
    weak var chatVCDelegate: NewChatViewControllerDelegate?
    
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
    @IBOutlet weak var expandMenuButtonView: NSView!
    
    @IBOutlet weak var mentionScrollViewLeadingConstraints: NSLayoutConstraint!
    @IBOutlet weak var mentionScrollViewBottomConstraints: NSLayoutConstraint!
    
    var mediaFullScreenView: MediaFullScreenView? = nil
    
    var newChatViewModel: NewChatViewModel!
    
    var contact: UserContact?
    var tribeAdmin: UserContact?
    var chat: Chat?
    var owner: UserContact!
    var deepLinkData : DeeplinkData? = nil
    
    var threadUUID: String? = nil
    var escapeMonitor: Any? = nil
    
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
    var threadVC: NewChatViewController? = nil
    
    static func instantiate(
        contactId: Int? = nil,
        chatId: Int? = nil,
        delegate: DashboardVCDelegate? = nil,
        chatVCDelegate: NewChatViewControllerDelegate? = nil,
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
        viewController.chatVCDelegate = chatVCDelegate
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
        
        chatTopView.checkRoute()
        NotificationCenter.default.addObserver(self, selector: #selector(handleImagePaste), name: .onFilePaste, object: nil)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        setupChatBottomView()
        fetchTribeData()
        configureMentionAutocompleteTableView()
        configureFetchResultsController()
        loadReplyableMeesage()
        addEscapeMonitor()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        chatTableDataSource?.saveSnapshotCurrentState()
        chatTableDataSource?.releaseMemory()
        
        closeThreadAndResetEscapeMonitor()
        
        NotificationCenter.default.removeObserver(self, name: .onFilePaste, object: nil)
    }
    
    deinit {
        botWebView = nil
    }
    
    override func viewDidLayout() {
        chatTableDataSource?.updateFrame()
    }
    
    func closeThreadAndResetEscapeMonitor() {
        shouldCloseThread()
        
        if let escapeMonitor = escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
        }
        
        escapeMonitor = nil
    }
    
    func addEscapeMonitor() {
        //add event monitor in case user never clicks the textfield
        if let escapeMonitor = escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
        }
    
        escapeMonitor = nil
    
        self.escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) in
            if event.keyCode == 53 && self.isThread { // 53 is the key code for the Escape key
                // Perform your action when the Escape key is pressed
                if let mediaFullScreenView = self.mediaFullScreenView {
                    mediaFullScreenView.closeView()
                    return nil
                } else if self.draggingView.isSendingMedia() {
                    self.draggingView.setup()
                    return nil
                }
            } else if event.modifierFlags.contains(.command) && event.characters?.uppercased() == "F" {
                self.didClickSearchButton()
            }
            return event
        }
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
        chatTableDataSource?.releaseMemory()
        
        botWebView = nil
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
        setupCollectionView()
    }
    
    func setupCollectionView() {
        mentionsScrollView.wantsLayer = true
        mentionsScrollView.layer?.cornerRadius = 9
        
        // Customize the scroll view's border
        mentionsScrollView.layer?.borderWidth = 1.0
        mentionsScrollView.layer?.borderColor = NSColor.black.withAlphaComponent(0.15).cgColor
    }
    
    func setupChatTopView() {
        view.bringSubviewToFront(chatTopView)
        view.bringSubviewToFront(threadHeaderView)
        
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
            threadUUID: threadUUID,
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
        threadVC = NewChatViewController.instantiate(
            contactId: self.contact?.id,
            chatId: self.chat?.id,
            delegate: delegate,
            chatVCDelegate: self,
            threadUUID: threadID
        )
        
        guard let threadVC = threadVC else {
            return
        }
        
        chatBottomView.messageFieldView.isThreadOpen = true
        
        WindowsManager.sharedInstance.showVCOnRightPanelWindow(
            with: "thread-chat".localized,
            identifier: "thread-chat-identifier",
            contentVC: threadVC,
            shouldReplace: false,
            panelFixedWidth: true
        )
    }
    
    func resizeSubviews(frame: NSRect) {
        view.frame = frame
        threadVC?.view.frame = frame
    }
    
    @objc func handleImagePaste(){
        if let _ = threadVC {
            return
        }
        let success = draggingView.performPasteOperation(pasteBoard: NSPasteboard.general)
        print(success)
    }
    
    private func loadReplyableMeesage() {
        if let replyableMessage = ChatTrackingHandler.shared.getReplyableMessageFor(chatId: chat?.id) {
            newChatViewModel.replyingTo = replyableMessage
            
            let isAtBottom = isChatAtBottom()
            
            chatBottomView.configureReplyViewFor(
                message: replyableMessage,
                owner: self.owner,
                withDelegate: self
            )
            
            if isAtBottom {
                shouldScrollToBottom()
                
                configureNewMessagesIndicatorWith(
                    newMsgCount: 0
                )
            }
        } else {
            chatBottomView.resetReplyView()
        }
    }
    
    func toggleExpandMenuButton(show: Bool) {
        expandMenuButtonView.isHidden = !show
    }
    
    @IBAction func expandMenuButtonClicked(_ sender: Any) {
        delegate?.shouldToggleLeftView(show: true)
    }
}
