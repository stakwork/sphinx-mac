//
//  ChatListViewController.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class ChatListViewController : DashboardSplittedViewController {

    ///IBOutlets
    @IBOutlet weak var headerView: NSView!
    @IBOutlet weak var balanceLabel: NSTextField!
    @IBOutlet weak var balanceUnitLabel: NSTextField!
    @IBOutlet weak var bottomBar: NSView!
    @IBOutlet weak var searchBarContainer: NSView!
    @IBOutlet weak var searchFieldContainer: NSBox!
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet weak var loadingWheelContainer: NSView!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var loadingChatsBox: NSBox!
    @IBOutlet weak var loadingChatsWheel: NSProgressIndicator!
    @IBOutlet weak var searchClearButton: NSButton!
    @IBOutlet weak var healthCheckView: HealthCheckView!
    @IBOutlet weak var upgradeBox: NSBox!
    @IBOutlet weak var upgradeButton: NSButton!
    @IBOutlet weak var chatListVCContainer: NSView!
    @IBOutlet weak var receiveButton: CustomButton!
    @IBOutlet weak var transactionsButton: CustomButton!
    @IBOutlet weak var sendButton: CustomButton!
    
    @IBOutlet weak var dashboardNavigationTabs: ChatsSegmentedControl! {
        didSet {
            dashboardNavigationTabs.configureFromOutlet(
                buttonTitles: [
                    "dashboard.tabs.friends".localized,
                    "dashboard.tabs.tribes".localized,
                ],
                delegate: self
            )
        }
    }
    
    ///Helpers
    let contactsService = ContactsService.sharedInstance
    let feedsManager = FeedsManager.sharedInstance
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    var walletBalanceService = WalletBalanceService()
    
    ///Loading
    var loading = false {
        didSet {
            healthCheckView.isHidden = loading
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [])
        }
    }
    
    var loadingChatList = true {
        didSet {
            loadingChatsBox.isHidden = !loadingChatList
            LoadingWheelHelper.toggleLoadingWheel(loading: loadingChatList, loadingWheel: loadingChatsWheel, color: NSColor.white, controls: [])
        }
    }
    
    ///Chat List VCs
    internal lazy var contactChatsContainerViewController: NewChatListViewController = {
        NewChatListViewController.instantiate(
            tab: NewChatListViewController.Tab.Friends,
            delegate: self
        )
    }()
    
    internal lazy var tribeChatsContainerViewController: NewChatListViewController = {
        NewChatListViewController.instantiate(
            tab: NewChatListViewController.Tab.Tribes,
            delegate: self
        )
    }()
    
    static func instantiate(
        delegate: DashboardVCDelegate?
    ) -> ChatListViewController {
        let viewController = StoryboardScene.Dashboard.chatListViewController.instantiate()
        viewController.delegate = delegate
        return viewController
    }
    
    ///Lifecycle events
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingChatList = true
        
        contactsService.configureFetchResultsController()
        
        prepareView()
        listenForPubKeyAndTribeJoin()
        
        setActiveTab(
            contactsService.selectedTab,
            loadData: false
        )
        
        NotificationCenter.default.removeObserver(self, name: .onContactsAndChatsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidChange), name: .onContactsAndChatsChanged, object: nil)
        
        resetSearchField()
    }
    
    override func viewDidLayout() {
        for childVC in self.children {
            childVC.view.frame = chatListVCContainer.bounds
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        loading = true
        
        configureHeaderAndBottomBar()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        listenForNotifications()
        loadFriendAndReload()
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.loadingChatList = false
        })
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
    }
    
    func prepareView() {
        receiveButton.cursor = .pointingHand
        sendButton.cursor = .pointingHand
        transactionsButton.cursor = .pointingHand
        
        searchField.setPlaceHolder(color: NSColor.Sphinx.PlaceholderText, font: NSFont(name: "Roboto-Regular", size: 14.0)!, string: "search".localized)
        searchField.delegate = self
        
        healthCheckView.delegate = self
        
        self.view.window?.makeFirstResponder(self)
    }
    
    func loadMessages(
        contactsProgress: Float = 0
    ) {
        let restoring = chatListViewModel.isRestoring()
        var contentProgressShare : Float = 0.0
        
        self.syncContentFeedStatus(
            restoring: restoring,
            progressCallback:  { contentProgress in
                contentProgressShare = 0.1
                
                if (contentProgress >= 0 && restoring) {
                    let contentProgress = Int(contentProgressShare * Float(contentProgress))
                    
                    DispatchQueue.main.async {
                        self.delegate?.shouldShowRestoreModal(
                            with: contentProgress + Int(contactsProgress * 100),
                            label: "restoring-content".localized,
                            buttonEnabled: false
                        )
                    }
                }
            },
            completionCallback: {
                self.chatListViewModel.syncMessages(
                    progressCallback: { (progress, restoring) in

                        DispatchQueue.main.async {
                            
                            if (restoring) {
                                self.loading = false
                                let messagesProgress : Int = Int(Float(progress) * (1.0 - contentProgressShare - contactsProgress))
                                
                                if (progress >= 0) {
                                    self.delegate?.shouldShowRestoreModal(
                                        with: messagesProgress + Int(contentProgressShare * 100) + Int(contactsProgress * 100),
                                        label: "restoring-messages".localized,
                                        buttonEnabled: true
                                    )
                                } else {
                                    self.newMessageBubbleHelper.showLoadingWheel(text: "fetching.old.messages".localized)
                                }
                            } else {
                                self.delegate?.shouldHideRetoreModal()
                            }
                        }
                        
                    }) { (_, _) in
                        DispatchQueue.main.async {
                            self.finishLoading()
                        }
                    }
            }
        )
    }
    
    internal func syncContentFeedStatus(
        restoring: Bool,
        progressCallback: @escaping (Int) -> (),
        completionCallback: @escaping () -> ()
    ) {
        if !restoring {
            completionCallback()
            return
        }
        
        CoreDataManager.sharedManager.saveContext()
        
        feedsManager.restoreContentFeedStatus(
            progressCallback: { contentProgress in
                progressCallback(contentProgress)
            },
            completionCallback: {
                completionCallback()
            }
        )
    }
    
    func loadFriendAndReload() {
        updateBalanceAndCheckVersion()
        
        if chatListViewModel.isRestoring() {
            DispatchQueue.main.async {
                self.delegate?.shouldShowRestoreModal(
                    with: 1,
                    label: "restoring-contacts".localized,
                    buttonEnabled: false
                )
            }
        }
        
        var contactsProgressShare : Float = 0.01
        
        chatListViewModel.loadFriends(
            progressCompletion: { restoring in
                if restoring {
                    
                    contactsProgressShare += 0.01
                    
                    DispatchQueue.main.async {
                        self.delegate?.shouldShowRestoreModal(
                            with: Int(contactsProgressShare * 100),
                            label: "restoring-contacts".localized,
                            buttonEnabled: false
                        )
                    }
                }
            }
        ) { restoring in
            self.loadMessages(
                contactsProgress: contactsProgressShare
            )
        }
    }
    
    func updateBalanceAndCheckVersion() {
        updateBalance()
        shouldCheckAppVersions()
    }
    
    func finishLoading() {
        newMessageBubbleHelper.hideLoadingWheel()
        loading = false
    }
    
    func shouldCheckAppVersions() {        
        API.sharedInstance.getAppVersions(callback: { v in
            let version = Int(v) ?? 0
            let appVersion = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0

            self.upgradeButton.isHidden = version <= appVersion
            self.upgradeBox.isHidden = version <= appVersion
        })
    }
    
    func selectRowFor(chatId: Int) {
        if let chat = Chat.getChatWith(id: chatId) {
            didClickRowAt(
                chatId: chat.id,
                contactId: chat.getConversationContact()?.id
            )
        }
    }
    
    @IBAction func refreshButtonClicked(_ sender: Any) {
        loading = true
        loadFriendAndReload()
    }
    
    @IBAction func addContactButtonClicked(_ sender: Any) {
        let addFriendVC = AddFriendViewController.instantiate(delegate: self, dismissDelegate: self)
        
        WindowsManager.sharedInstance.showContactWindow(
            vc: addFriendVC,
            title: "new.contact".localized,
            identifier: "new-contact-window",
            height: 500
        )
    }
    
    func listenForPubKeyAndTribeJoin() {
        NotificationCenter.default.addObserver(
            forName: .onPubKeyClick,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] (n: Notification) in
            
            guard let self = self else { return }
            
            if let pubkey = n.userInfo?["pub-key"] as? String {
                if pubkey == UserData.sharedInstance.getUserPubKey() { return }
                let (pk, _) = pubkey.pubkeyComponents
                let (existing, user) = pk.isExistingContactPubkey()
                
                if let user = user, existing {
                    
                    let chat = user.getChat()
                    
                    if chat?.isPublicGroup() == true {
                        self.contactsService.selectedTab = .tribes
                        self.contactsService.selectedTribeId = chat?.getObjectId()
                        self.setActiveTab(.tribes, shouldSwitchChat: false)
                    } else {
                        self.contactsService.selectedTab = .friends
                        self.contactsService.selectedFriendId = chat?.getObjectId() ?? user.getObjectId()
                        self.setActiveTab(.friends, shouldSwitchChat: false)
                    }
                    
                    self.dashboardNavigationTabs.updateButtonsOnIndexChange()
                    
                    self.didClickRowAt(
                        chatId: chat?.id,
                        contactId: user.id
                    )
                } else {
                    
                    let contactVC = NewContactViewController.instantiate(
                        delegate: self,
                        pubkey: pubkey
                    )
                    
                    WindowsManager.sharedInstance.showContactWindow(
                        vc: contactVC,
                        title: "new.contact".localized,
                        identifier: "new-contact-window",
                        height: 500
                    )
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .onJoinTribeClick,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] (n: Notification) in
            guard let self = self else { return }
            
            if let tribeLink = n.userInfo?["tribe_link"] as? String {
                if let tribeInfo = GroupsManager.sharedInstance.getGroupInfo(query: tribeLink), let uuid = tribeInfo.uuid {
                    if let chat = Chat.getChatWith(uuid: uuid) {
                        
                        self.contactsService.selectedTab = .tribes
                        self.contactsService.selectedTribeId = chat.getObjectId()
                        self.dashboardNavigationTabs.updateButtonsOnIndexChange()
                        self.setActiveTab(.tribes, shouldSwitchChat: false)
                        
                        self.didClickRowAt(
                            chatId: chat.id,
                            contactId: chat.getConversationContact()?.id
                        )
                    } else {
                        let joinTribeVC = JoinTribeViewController.instantiate(
                            tribeInfo: tribeInfo,
                            delegate: self
                        )

                        WindowsManager.sharedInstance.showJoinTribeWindow(
                            vc: joinTribeVC,
                            title: "join.tribe".localized
                        )
                    }
                }
            }
        }
    }
    
    @IBAction func upgradeButtonClicked(_ sender: Any) {
        if let url = URL(string: "https://testflight.apple.com/join/QoaCkJn6") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func hideMenuButtonClicked(_ sender: Any) {
        delegate?.shouldToggleLeftView(show: false)
    }
    
    @IBAction func clearButtonClicked(_ sender: Any) {
        resetSearchField()
    }
    
    @IBAction func receiveButtonClicked(_ sender: Any) {
        handleReceiveClick()
    }
    
    @IBAction func sendButtonClicked(_ sender: Any) {
        handleSentClick()
    }
    
    @IBAction func transactionsButtonClicked(_ sender: Any) {
        WindowsManager.sharedInstance.showTransationsListWindow(
            vc: TransactionsListViewController.instantiate()
        )
    }
}

extension ChatListViewController: NewContactDismissDelegate {
    func shouldDismissView() {
        WindowsManager.sharedInstance.dismissViewFromCurrentWindow()
    }
}


