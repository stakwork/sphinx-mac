//
//  ChatListViewController.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class ChatListViewController : DashboardSplittedViewController {

    @IBOutlet weak var headerView: NSView!
    @IBOutlet weak var balanceLabel: NSTextField!
    @IBOutlet weak var balanceUnitLabel: NSTextField!
    @IBOutlet weak var bottomBar: NSView!
    @IBOutlet weak var searchBarContainer: NSView!
    @IBOutlet weak var searchFieldContainer: NSBox!
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet weak var chatListCollectionView: NSCollectionView!
    @IBOutlet weak var loadingWheelContainer: NSView!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var searchClearButton: NSButton!
    @IBOutlet weak var healthCheckView: HealthCheckView!
    @IBOutlet weak var upgradeBox: NSBox!
    @IBOutlet weak var upgradeButton: NSButton!
    
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    var walletBalanceService = WalletBalanceService()
    
    var chatListDataSource: ChatListDataSource! = nil
    var chatListObjectsArray = [ChatListCommonObject]()
    
    var loading = false {
        didSet {
            healthCheckView.isHidden = loading
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [])
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareView()
        listenForPubKeyAndTribeJoin()
    }
    
    override func viewDidLayout() {
        chatListDataSource?.updateFrame()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        loading = true
        
        updateContactsAndReload()
        configureHeaderAndBottomBar()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        listenForNotifications()
        updateBalance()
        loadFriendAndReload()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        NotificationCenter.default.removeObserver(self, name: .onBalanceDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onJoinTribeClick, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onPubKeyClick, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onTribeImageChanged, object: nil)
    }
    
    func prepareView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: self.view.frame.width, height: 60.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        chatListCollectionView.collectionViewLayout = flowLayout
        
        searchField.setPlaceHolder(color: NSColor.Sphinx.PlaceholderText, font: NSFont(name: "Roboto-Regular", size: 14.0)!, string: "search".localized)
        searchField.delegate = self
        
        healthCheckView.delegate = self
        
        self.view.window?.makeFirstResponder(self)
    }
    
    func loadMessages() {        
        updateContactsAndReload()
        
        self.chatListViewModel.syncMessages(progressCallback: { message in
            DispatchQueue.main.async {
                self.loading = false
                self.newMessageBubbleHelper.showLoadingWheel(text: message)
            }
        }) { (_, _) in
            DispatchQueue.main.async {
                self.updateContactsAndReload()
                self.finishLoading()
            }
        }
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
        chatListObjectsArray = contactsService.getChatListObjects()
        loadDataSource()
        shouldCheckAppVersions()
    }
    
    func finishLoading() {
        newMessageBubbleHelper.hideLoadingWheel()
        loading = false
    }
    
    func loadDataSource() {
        if chatListDataSource == nil {
            chatListDataSource = ChatListDataSource(collectionView: chatListCollectionView, delegate: self)
            chatListDataSource?.setDataAndReload(chatListObjects: chatListObjectsArray)
        } else {
            chatListDataSource?.updateDataAndReload(chatListObjects: chatListObjectsArray)
        }
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
        chatListDataSource?.selectedChatId = chatId
        chatListCollectionView.reloadData()
    }
    
    @IBAction func refreshButtonClicked(_ sender: Any) {        
        loading = true
        updateBalance()
        chatListDataSource.resetSelection()
        loadFriendAndReload()
        delegate?.didReloadDashboard()
    }
    
    @IBAction func addContactButtonClicked(_ sender: Any) {
        let addFriendVC = AddFriendViewController.instantiate(contactsService: contactsService, delegate: self)
        WindowsManager.sharedInstance.showContactWindow(vc: addFriendVC, window: view.window, title: "new.contact".localized, identifier: "new-contact-window", size: CGSize(width: 414, height: 600))
    }
    
    func listenForPubKeyAndTribeJoin() {
        NotificationCenter.default.addObserver(forName: .onPubKeyClick, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            
            if let pubkey = n.userInfo?["pub-key"] as? String {
                if pubkey == UserData.sharedInstance.getUserPubKey() { return }
                let (pk, _) = pubkey.pubkeyComponents
                let (existing, user) = pk.isExistingContactPubkey()
                
                if let user = user, existing {
                    vc.chatListDataSource.shouldSelectContactOrChat(user)
                } else {
                    let contactVC = NewContactViewController.instantiate(contactsService: vc.contactsService, delegate: self, pubkey: pubkey)
                    WindowsManager.sharedInstance.showContactWindow(vc: contactVC, window: vc.view.window, title: "new.contact".localized, identifier: "new-contact-window", size: CGSize(width: 414, height: 600))
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: .onJoinTribeClick, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            
            if let tribeLink = n.userInfo?["tribe_link"] as? String {
                if let tribeInfo = GroupsManager.sharedInstance.getGroupInfo(query: tribeLink), let uuid = tribeInfo.uuid {
                    if let chat = Chat.getChatWith(uuid: uuid) {
                        vc.chatListDataSource.shouldSelectContactOrChat(chat)
                    } else {
                        let joinTribeVC = JoinTribeViewController.instantiate(tribeInfo: tribeInfo, delegate: vc)
                        WindowsManager.sharedInstance.showContactWindow(vc: joinTribeVC, window: vc.view.window, title: "join.tribe".localized.uppercased(), identifier: "join-tribe-window", size: CGSize(width: 414, height: 870))
                    }
                }
            }
        }
    }
    
    @IBAction func upgradeButtonClicked(_ sender: Any) {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/apple-store/id1483956418?mt=8") {
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
