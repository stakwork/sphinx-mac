//
//  DashboardViewController.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 13/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class DashboardViewController: NSViewController {
    
    @IBOutlet weak var dashboardSplitView: NSSplitView!
    @IBOutlet weak var leftSplittedView: NSView!
    @IBOutlet weak var rightSplittedView: NSView!
    @IBOutlet weak var modalsContainerView: NSView!
    
    var mediaFullScreenView: MediaFullScreenView? = nil
    
    var contactsService : ContactsService! = nil
    var chatViewModel: ChatViewModel! = nil
    var chatListViewModel: ChatListViewModel! = nil
    var deeplinkData: DeeplinkData? = nil
    
    var detailViewController : ChatViewController? = nil
    var listViewController : ChatListViewController? = nil
    
    let kDetailSegueIdentifier = "ChatViewControllerSegue"
    let kListSegueIdentifier = "ChatListViewControllerSegue"
    
    let kWindowMinWidthWithLeftColumn: CGFloat = 950
    let kWindowMinWidthWithoutLeftColumn: CGFloat = 600
    let kWindowMinHeight: CGFloat = 735
    
    public static let kPodcastPlayerWidth: CGFloat = 350
    
    static func instantiate() -> DashboardViewController {
        let viewController = StoryboardScene.Dashboard.dashboardViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        AttachmentsManager.sharedInstance.runAuthentication()
        
        listerForNotifications()
        
        contactsService = ContactsService()
        chatListViewModel = ChatListViewModel(contactsService: contactsService)
        chatViewModel = ChatViewModel()
        
        dashboardSplitView.delegate = self
        SphinxSocketManager.sharedInstance.setDelegate(delegate: self)
        
        let windowState = WindowsManager.sharedInstance.getWindowState()
        leftSplittedView.isHidden = windowState.menuCollapsed
        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.themeChangedNotification(notification:)), name: .onInterfaceThemeChanged, object: nil)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        listViewController?.delegate = self
        detailViewController?.delegate = self
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        listViewController?.delegate = nil
        detailViewController?.delegate = nil
        
        NotificationCenter.default.removeObserver(self, name: .shouldUpdateDashboard, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shouldTrackPosition, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shouldReloadViews, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shouldResetChat, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shouldReloadChatsList, object: nil)
        NotificationCenter.default.removeObserver(self, name: .chatNotificationClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onAuthDeepLink, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onPersonDeepLink, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onSaveProfileDeepLink, object: nil)
    }
    
    @objc func themeChangedNotification(notification: Notification) {
        detailViewController?.chatCollectionView.reloadData()
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            NSAppearance.current = self.view.effectiveAppearance
            self.listViewController?.configureHeaderAndBottomBar()
            self.listViewController?.loadFriendAndReload()
        })
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch (segue.identifier) {
        case kListSegueIdentifier:
            listViewController = (segue.destinationController as? ChatListViewController) ?? nil
            break
        case kDetailSegueIdentifier:
            detailViewController = (segue.destinationController as? ChatViewController) ?? nil
            break
        default:
            break
        }
        
        if let splitedVC = segue.destinationController as? DashboardSplittedViewController {
            splitedVC.delegate = self
            splitedVC.setDataModels(contactsService: contactsService,
                                    chatListViewModel: chatListViewModel,
                                    chatViewModel: chatViewModel)
        }
    }
    
    func listerForNotifications() {
        NotificationCenter.default.addObserver(forName: .shouldUpdateDashboard, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.reloadData()
        }
        
        NotificationCenter.default.addObserver(forName: .shouldReloadViews, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.reloadView()
        }
        
        NotificationCenter.default.addObserver(forName: .shouldTrackPosition, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.detailViewController?.trackChatScrollPosition()
        }
        
        NotificationCenter.default.addObserver(forName: .shouldResetChat, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.resetChatIfDeleted()
        }
        
        NotificationCenter.default.addObserver(forName: .shouldReloadChatsList, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.shouldReloadChatList()
        }
        
        NotificationCenter.default.addObserver(forName: .chatNotificationClicked, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            
            if let chatId = n.userInfo?["chat-id"] as? Int, let chat = Chat.getChatWith(id: chatId) {
                vc.shouldGoToChat(chat: chat)
                
                if let message = n.userInfo?["message"] as? String {
                    vc.detailViewController?.sendMessageWith(text: message)
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: .onAuthDeepLink, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            vc.showDashboardModalsVC(n: n)
        }
        
        NotificationCenter.default.addObserver(forName: .onPersonDeepLink, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            vc.showDashboardModalsVC(n: n)
        }
        
        NotificationCenter.default.addObserver(forName: .onSaveProfileDeepLink, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            vc.showDashboardModalsVC(n: n)
        }
        
        NotificationCenter.default.addObserver(forName: .onStakworkAuthDeepLink, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            vc.showDashboardModalsVC(n: n)
        }
        
        NotificationCenter.default.addObserver(forName: .onRedeemSatsDeepLink, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            vc.showDashboardModalsVC(n: n)
        }
        
        NotificationCenter.default.addObserver(forName: .onInvoiceDeepLink, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            vc.createInvoice(n: n)
        }
        
        NotificationCenter.default.addObserver(forName: .onShareContentDeeplink, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            print("Deeplink found!")
            var success = false
            if let query = n.userInfo?["query"] as? String,
               let feedID = query.getLinkValueFor(key: "feedID"),
               let itemID = query.getLinkValueFor(key: "itemID"),
               let timestamp = query.getLinkValueFor(key: "atTime"){
                print(query)
                let feeds = FeedsManager.sharedInstance.fetchFeeds()
                if let feed = feeds.filter({$0.feedID == feedID}).first,
                   let chat = feed.chat{
                    let finalTS = Int(timestamp) ?? 0
                    vc.deeplinkData = DeeplinkData(feedID: feedID, itemID: itemID, timestamp: finalTS)
                    vc.didClickOnChatRow(object: chat)
                    success = true
                    print(chat)
                }
            }
            if success == false{
                //throw error
                print("Error opening content deeplink")
            }
        }
    }
    
    
    func createInvoice(n: Notification) {
        if let query = n.userInfo?["query"] as? String {
            if let amountString = query.getLinkValueFor(key: "amount"), let amount = Int(amountString) {
                let params = ["amount" : amount as AnyObject]
                
                API.sharedInstance.createInvoice(parameters: params, callback: { (_, invoice) in
                    if let invoice = invoice, !invoice.isEmpty {
                        let invoiceVC = ShareInviteCodeViewController.instantiate(qrCodeString: invoice, viewMode: .Invoice)
                        WindowsManager.sharedInstance.showInvoiceWindow(vc: invoiceVC, window: self.view.window)
                    }
                }, errorCallback: {})
            }
        }
    }
    
    func showDashboardModalsVC(n: Notification) {
        if let query = n.userInfo?["query"] as? String {
            for childVC in self.children {
                if let childVC = childVC as? DashboardModalsViewController {
                    self.modalsContainerView.isHidden = false
                    childVC.showWithQuery(query, and: self)
                }
            }
        }
    }
    
    func shouldGoToChat(chat: Chat) {
        self.presentChatVC(object: chat)
        self.listViewController?.selectRowFor(chatId: chat.id)
    }
    
    func resetChatIfDeleted() {
        let contactFaulted = detailViewController?.contact?.isFault ?? false
        let chatFaulted = detailViewController?.chat?.isFault ?? false
        
        if contactFaulted || chatFaulted {
            detailViewController?.loadChatFor(contactsService: contactsService)
        }
    }
    
    func reloadView() {
        self.listViewController?.chatListCollectionView.reloadData()
        self.detailViewController?.chatCollectionView.reloadData()
    }
    
    func reloadData() {
        self.listViewController?.chatListDataSource.reloadSelectedRow()
        
        self.chatListViewModel.loadFriends {
            let chatId = self.detailViewController?.chat?.id
            self.chatListViewModel.syncMessages(chatId: chatId, progressCallback: { (_, restoring) in
                self.chatListViewModel.calculateBadges()
                self.listViewController?.updateContactsAndReload()
            }) { (_, count) in
                if count > 0 {
                    self.detailViewController?.initialLoad()
                }

                self.listViewController?.updateContactsAndReload()
                self.listViewController?.loading = false

                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    appDelegate.setBadge(count: TransactionMessage.getReceivedUnseenMessagesCount())
                }
            }
        }
    }
}

extension DashboardViewController : NSSplitViewDelegate {
    func splitViewDidResizeSubviews(_ notification: Notification) {
        if let window = view.window {
            let (minWidth, _) = getWindowMinWidth(leftColumnVisible: !leftSplittedView.isHidden)
            window.minSize = CGSize(width: minWidth, height: kWindowMinHeight)
            
            if window.frame.width < minWidth {
                let newFrame = CGRect(x: window.frame.origin.x, y: window.frame.origin.y, width: minWidth, height: window.frame.height)
                view.window?.setFrame(newFrame, display: true)
            }
            detailViewController?.toggleExpandMenuButton(show: leftSplittedView.isHidden)
        }
    }
}

extension DashboardViewController : DashboardVCDelegate {
    func didClickOnChatRow(object: ChatListCommonObject) {
        if let contact = object as? UserContact, contact.isPending() {
            if let invite = contact.invite {
                if invite.isPendingPayment() {
                    payInvite(invite: invite)
                    return
                }

                let (ready, title, message) = invite.getInviteStatusForAlert()
                if ready {
                    goToInviteCodeString(inviteCode: contact.invite?.inviteString ?? "")
                } else {
                    AlertHelper.showAlert(title: title, message: message)
                }
            }
        } else {
            presentChatVC(object: object)
        }
    }
    
    func payInvite(invite: UserInvite) {
        AlertHelper.showTwoOptionsAlert(title: "pay.invitation".localized, message: "", confirm: {
            self.chatListViewModel.payInvite(invite: invite, completion: { contact in
                if let contact = contact {
                    self.didUpdateContact(contact: contact)
                } else {
                    AlertHelper.showAlert(title: "generic.error.title".localized, message: "payment.failed".localized)
                }
            })
        })
    }
    
    func goToInviteCodeString(inviteCode: String) {
        if inviteCode == "" {
            return
        }
        let shareInviteCodeVC = ShareInviteCodeViewController.instantiate(qrCodeString: inviteCode, viewMode: .Invite)
        WindowsManager.sharedInstance.showInviteCodeWindow(vc: shareInviteCodeVC, window: view.window)
    }
    
    func didReloadDashboard() {
        detailViewController?.reload()
    }
    
    func shouldReloadChatList() {
        listViewController?.updateContactsAndReload()
    }
    
    func presentChatVC(object: ChatListCommonObject) {
        let chat = (object as? Chat) ?? ((object as? UserContact)?.getConversation())
        let contact = (object as? UserContact) ?? (object as? Chat)?.getContact()
        detailViewController?.loadChatFor(contact: contact, chat: chat, contactsService: contactsService)
        detailViewController?.configureMentionAutocompleteTableView()
        if(deeplinkData != nil){
            detailViewController?.deeplinkData = deeplinkData
        }
        deeplinkData = nil
    }
    
    func shouldShowFullMediaFor(message: TransactionMessage) {
        goToMediaFullView(message: message)
    }
    
    func goToMediaFullView(message: TransactionMessage?) {
        if mediaFullScreenView == nil {
            mediaFullScreenView = MediaFullScreenView()
        }
        
        if let mediaFullScreenView = mediaFullScreenView, let message = message {
            view.addSubview(mediaFullScreenView)
            
            mediaFullScreenView.delegate = self
            mediaFullScreenView.constraintTo(view: view)
            mediaFullScreenView.showWith(message: message)
            mediaFullScreenView.isHidden = false
        }
    }
    
    func shouldToggleLeftView(show: Bool?) {
        if let window = view.window {
            let menuVisible = show ?? !isLeftMenuCollapsed()
            let (minWidth, _) = getWindowMinWidth(leftColumnVisible: menuVisible)
            leftSplittedView.isHidden = !menuVisible
            window.minSize = CGSize(width: minWidth, height: kWindowMinHeight)
            
            let newWidth = menuVisible ? max(window.frame.width, minWidth) : window.frame.width
            let newFrame = CGRect(x: window.frame.origin.x, y: window.frame.origin.y, width: newWidth, height: window.frame.height)
            window.setFrame(newFrame, display: true)
            
            detailViewController?.toggleExpandMenuButton(show: !menuVisible)
        }
    }
    
    func isLeftMenuCollapsed() -> Bool {
        return leftSplittedView.isHidden
    }
    
    func getWindowMinWidth(leftColumnVisible: Bool) -> (CGFloat, CGFloat) {
        let podcastPlayerWidth =  detailViewController?.podcastContainerWidth.constant ?? 0
        let leftPanelWidth = leftSplittedView.frame.width
        let minWidth: CGFloat = leftColumnVisible ? kWindowMinWidthWithoutLeftColumn + leftPanelWidth : kWindowMinWidthWithoutLeftColumn
        return (minWidth + podcastPlayerWidth, leftPanelWidth)
    }
    
    func shouldShowRestoreModal(
        with progress: Int,
        messagesStartProgress: Int
    ) {
        for childVC in self.children {
            if let childVC = childVC as? DashboardModalsViewController {
                modalsContainerView.isHidden = false
                
                childVC.showProgressViewWith(
                    with: progress,
                    messagesStartProgress: messagesStartProgress,
                    delegate: self
                )
            }
        }
    }
    
    func shouldHideRetoreModal() {
        didFinishRestoring()
    }
    
    func showFinishingRestore() {
        for childVC in self.children {
            if let childVC = childVC as? DashboardModalsViewController {
                modalsContainerView.isHidden = false
                
                childVC.setFinishingRestore()
            }
        }
    }
}

extension DashboardViewController : SocketManagerDelegate {
    func didReceiveMessage(message: TransactionMessage, onChat: Bool) {
        listViewController?.didReceiveMessage(message: message)
        
        if onChat {
            detailViewController?.didReceiveMessage(message: message)
        }
    }
    
    func didReceiveConfirmation(message: TransactionMessage) {
        listViewController?.didReceiveConfirmation(message: message)
        detailViewController?.didReceiveConfirmation(message: message)
    }
    
    func didReceivePurchaseUpdate(message: TransactionMessage) {
        listViewController?.didReceivePurchaseUpdate(message: message)
        detailViewController?.didReceivePurchaseUpdate(message: message)
    }
    
    func shouldShowAlert(message: String) {
        listViewController?.shouldShowAlert(message: message)
        detailViewController?.shouldShowAlert(message: message)
    }
    
    func didUpdateContact(contact: UserContact) {
        listViewController?.didUpdateContact(contact: contact)
        detailViewController?.didUpdateContact(contact: contact)
    }
    
    func didReceiveOrUpdateGroup() {
        listViewController?.didReceiveOrUpdateGroup()
    }
    
    func didUpdateChat(chat: Chat) {
        listViewController?.didUpdateChat(chat: chat)
        detailViewController?.didUpdateChat(chat: chat)
    }
}

extension DashboardViewController : MediaFullScreenDelegate {
    func willDismissView() {
        if let mediaFullScreenView = mediaFullScreenView {
            mediaFullScreenView.removeFromSuperview()
            self.mediaFullScreenView = nil
        }
    }
}

extension DashboardViewController : PeopleModalsViewControllerDelegate {
    func shouldHideContainer() {
        modalsContainerView.isHidden = true
    }
}

extension DashboardViewController : RestoreModalViewControllerDelegate {
    func didFinishRestoreManually() {
        chatListViewModel.finishRestoring()
        showFinishingRestore()
    }
    
    func didFinishRestoring() {
        modalsContainerView.isHidden = true
        
        listViewController?.updateContactsAndReload()
        listViewController?.finishLoading()
    }
}
