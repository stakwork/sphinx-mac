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
    
    @IBOutlet weak var dashboardNavigationTabs: ChatsSegmentedControl! {
        didSet {
            dashboardNavigationTabs.configureFromOutlet(
                buttonTitles: [
                    "dashboard.tabs.friends".localized,
                    "dashboard.tabs.tribes".localized,
                ],
                initialIndex: 0,
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
    
    ///Lifecycle events
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareView()
        listenForPubKeyAndTribeJoin()
    }
    
    override func viewDidLayout() {
        for childVC in self.children {
            childVC.view.frame = chatListVCContainer.frame
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        loadingChatList = true
        loading = true
        
        updateContactsAndReload()
        configureHeaderAndBottomBar()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        setActiveTab(.friends)
        
        NotificationCenter.default.removeObserver(self, name: .onContactsAndChatsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dataDidChange), name: .onContactsAndChatsChanged, object: nil)
        
        listenForNotifications()
        updateBalance()
        loadFriendAndReload()
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.loadingChatList = false
        })
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        NotificationCenter.default.removeObserver(self, name: .onBalanceDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onJoinTribeClick, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onPubKeyClick, object: nil)
    }
    
    func prepareView() {
        searchField.setPlaceHolder(color: NSColor.Sphinx.PlaceholderText, font: NSFont(name: "Roboto-Regular", size: 14.0)!, string: "search".localized)
        searchField.delegate = self
        
        healthCheckView.delegate = self
        
        self.view.window?.makeFirstResponder(self)
    }
    
    func loadMessages() {        
        updateContactsAndReload()
        
        let restoring = chatListViewModel.isRestoring()
        var contentProgressShare : Float = 0.0
        
        self.syncContentFeedStatus(
            restoring: restoring,
            progressCallback:  { contentProgress in
                contentProgressShare = 0.1
                
                if (contentProgress >= 0 && restoring) {
                    DispatchQueue.main.async {
                        self.delegate?.shouldShowRestoreModal(
                            with: Int(contentProgressShare * Float(contentProgress)),
                            messagesStartProgress: Int(contentProgressShare * Float(100))
                        )
                    }
                }
            },
            completionCallback: {
                self.chatListViewModel.syncMessages(
                    progressCallback: { (progress, restoring) in

                        DispatchQueue.main.async {
                            
                            self.chatListViewModel.calculateBadges()
                            self.updateContactsAndReload()
                            
                            if (restoring) {
                                self.loading = false
                                let messagesProgress : Int = Int(Float(progress) * (1.0 - contentProgressShare))
                                
                                if (progress >= 0) {
                                    self.delegate?.shouldShowRestoreModal(
                                        with: messagesProgress + Int(contentProgressShare * 100),
                                        messagesStartProgress: Int(contentProgressShare * Float(100))
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
                            self.updateContactsAndReload()
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
        guard let chatListViewModel = chatListViewModel else {
            return
        }
        
        chatListViewModel.loadFriends() {
            self.loadMessages()
        }
    }
    
    func updateContactsAndReload() {
        updateBalance()
        
        chatListViewModel.updateContactsAndChats()
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
                selectedObjectId: chat.getObjectId(),
                chatId: chat.id,
                contactId: chat.getConversationContact()?.id
            )
        }
    }
    
    @IBAction func refreshButtonClicked(_ sender: Any) {
        loading = true
        updateBalance()
        loadFriendAndReload()
        delegate?.didReloadDashboard()
    }
    
    @IBAction func addContactButtonClicked(_ sender: Any) {
        let addFriendVC = AddFriendViewController.instantiate(delegate: self)
        
        WindowsManager.sharedInstance.showContactWindow(
            vc: addFriendVC,
            window: view.window,
            title: "new.contact".localized,
            identifier: "new-contact-window",
            size: CGSize(width: 414, height: 600)
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
                    
                    self.didClickRowAt(
                        selectedObjectId: chat?.getObjectId() ?? user.getObjectId(),
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
                        window: self.view.window,
                        title: "new.contact".localized,
                        identifier: "new-contact-window",
                        size: CGSize(width: 414, height: 600)
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
                        self.didClickRowAt(
                            selectedObjectId: chat.getObjectId(),
                            chatId: chat.id,
                            contactId: chat.getConversationContact()?.id
                        )
                    } else {
                        let joinTribeVC = JoinTribeViewController.instantiate(
                            tribeInfo: tribeInfo,
                            delegate: self
                        )
                        
                        WindowsManager.sharedInstance.showContactWindow(
                            vc: joinTribeVC,
                            window: self.view.window,
                            title: "join.tribe".localized.uppercased(),
                            identifier: "join-tribe-window",
                            size: CGSize(width: 414, height: 870)
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
}


