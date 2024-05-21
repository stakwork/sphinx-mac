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
    @IBOutlet weak var dashboardRightSplitView: NSSplitView!
    @IBOutlet weak var leftSplittedView: NSView!
    @IBOutlet weak var rightSplittedView: NSView!
    @IBOutlet weak var rightDetailSplittedView: NSView!
    @IBOutlet weak var rightDetailViewMinWidth: NSLayoutConstraint!
    @IBOutlet weak var rightDetailViewMaxWidth: NSLayoutConstraint!
    
    @IBOutlet weak var modalsContainerView: NSView!
    
    @IBOutlet weak var presenterBlurredBackground: NSVisualEffectView!
    @IBOutlet weak var presenterContainerView: NSView!
    @IBOutlet weak var presenterContainerBGView: NSBox!
    @IBOutlet weak var presenterContentBox: NSBox!
    @IBOutlet weak var presenterTitleLabel: NSTextField!
    @IBOutlet weak var presenterHeaderDivider: NSView!
    @IBOutlet weak var presenterBackButton: CustomButton!
    @IBOutlet weak var presenterCloseButton: CustomButton!
    @IBOutlet weak var presenterViewHeightConstraint: NSLayoutConstraint!
    
    weak var presenter: DashboardPresenterViewController?
    var presenterBackHandler: (() -> ())? = nil
    var presenterIdentifier: String?
    
    var dashboardDetailViewController: DashboardDetailViewController?
    
    var mediaFullScreenView: MediaFullScreenView? = nil
    
    var chatListViewModel: ChatListViewModel! = nil
    var deeplinkData: DeeplinkData? = nil
    
    let contactsService = ContactsService.sharedInstance
    
    var newDetailViewController : NewChatViewController? = nil
    var listViewController : ChatListViewController? = nil
    
    let kDetailSegueIdentifier = "ChatViewControllerSegue"
    let kListSegueIdentifier = "ChatListViewControllerSegue"
    
    let kWindowMinWidthWithLeftColumn: CGFloat = 950
    let kWindowMinWidthWithoutLeftColumn: CGFloat = 600
    let kWindowMinHeight: CGFloat = 735
    
    public static let kPodcastPlayerWidth: CGFloat = 350
    
    public static let kRightPanelMaxWidth: CGFloat = 450
    public static let kRightPanelMinWidth: CGFloat = 320
    
    var resizeTimer : Timer? = nil
    var escapeMonitor: Any? = nil
    
    static func instantiate() -> DashboardViewController {
        let viewController = StoryboardScene.Dashboard.dashboardViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        AttachmentsManager.sharedInstance.runAuthentication(forceAuthenticate: true)
        
        listerForNotifications()
        
        chatListViewModel = ChatListViewModel()
        
        dashboardSplitView.delegate = self
        dashboardSplitView.dividerStyle = .thick
        dashboardSplitView.setValue(NSColor.Sphinx.Divider2, forKey: "dividerColor")
        
        dashboardRightSplitView.delegate = self
        dashboardRightSplitView.dividerStyle = .thin
        dashboardRightSplitView.setValue(NSColor.Sphinx.Divider2, forKey: "dividerColor")
        
        SphinxSocketManager.sharedInstance.setDelegate(delegate: self)
        
        let windowState = WindowsManager.sharedInstance.getWindowState()
        leftSplittedView.isHidden = windowState.menuCollapsed
        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.themeChangedNotification(notification:)), name: .onInterfaceThemeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleImageNotification(_:)), name: .webViewImageClicked, object: nil)
        
        listenForResize()
        addEscapeMonitor()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        listViewController?.delegate = self
        rightDetailSplittedView.isHidden = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        handleDeepLink()
        addPresenterVC()
        addDetailVCPresenter()
    }
    
    func addPresenterVC() {
        presenterBlurredBackground.blendingMode = .withinWindow
        presenterBlurredBackground.material = .fullScreenUI
        presenterBlurredBackground.alphaValue = 1
        
        presenterBackButton.cursor = .pointingHand
        presenterCloseButton.cursor = .pointingHand
        
        if let _ = presenter {
            return
        }
        presenter = DashboardPresenterViewController.instantiate()
        
        if let presenter {
            self.addChildVC(
                child: presenter,
                container: self.presenterContainerView
            )
            
            self.presenterContainerBGView.isHidden = true
        }
    }
    
    func addDetailVCPresenter() {
        if let _ = dashboardDetailViewController {
            return
        }
        dashboardDetailViewController = DashboardDetailViewController.instantiate(delegate: self)
        
        if let dashboardDetailViewController {
            self.addChildVC(
                child: dashboardDetailViewController,
                container: self.rightDetailSplittedView
            )
            
            dashboardDetailViewController.view.frame = rightDetailSplittedView.bounds
            self.rightDetailSplittedView.isHidden = true
        }
    }
    
    fileprivate func listenForResize() {
        NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            
            if let presenter = self?.presenter {
                if let bounds = self?.presenterContainerView?.bounds {
                    presenter.view.frame = bounds
                }
            }
            
            if let detailVC = self?.dashboardDetailViewController {
                if let bounds = self?.rightDetailSplittedView.bounds {
                    detailVC.view.frame = bounds
                }
            }
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        listViewController?.delegate = nil
        
        NotificationCenter.default.removeObserver(self, name: .shouldUpdateDashboard, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shouldTrackPosition, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shouldReloadViews, object: nil)
        NotificationCenter.default.removeObserver(self, name: .shouldResetChat, object: nil)
        NotificationCenter.default.removeObserver(self, name: .chatNotificationClicked, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onAuthDeepLink, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onPersonDeepLink, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onSaveProfileDeepLink, object: nil)
        NotificationCenter.default.removeObserver(self, name: .webViewImageClicked, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSWindow.didResizeNotification, object: nil)
    }
    
    func handleDeepLink() {
        if let linkQuery: String = UserDefaults.Keys.linkQuery.get(), let url = URL(string: linkQuery) {
            DeepLinksHandlerHelper.handleLinkQueryFrom(url: url)
            UserDefaults.Keys.linkQuery.removeValue()
        }
    }
    
    @IBAction func closeButtonTapped(_ sender: NSButton) {
        closePresenter()
    }
    
    func closePresenter() {
        WindowsManager.sharedInstance.dismissViewFromCurrentWindow()
    }
    
    @IBAction func presenterBackButtonTapped(_ sender: NSButton) {
        if let presenterBackHandler = presenterBackHandler {
            presenterBackHandler()
        }
    }
    
    @objc func themeChangedNotification(notification: Notification) {
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
            newDetailViewController = (segue.destinationController as? NewChatViewController) ?? nil
            break
        default:
            break
        }
        
        if let splitedVC = segue.destinationController as? DashboardSplittedViewController {
            splitedVC.delegate = self
        }
    }
    
    func listerForNotifications() {
        NotificationCenter.default.addObserver(forName: .shouldUpdateDashboard, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.reloadData()
        }
        
        NotificationCenter.default.addObserver(forName: .shouldReloadViews, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.reloadView()
        }
        
        NotificationCenter.default.addObserver(forName: .shouldResetChat, object: nil, queue: OperationQueue.main) { _ in
            ///Reset chat view
        }
        
        NotificationCenter.default.addObserver(forName: .chatNotificationClicked, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            
            if let chatId = n.userInfo?["chat-id"] as? Int, let chat = Chat.getChatWith(id: chatId) {
                
                if chat.isPublicGroup() {
                    vc.contactsService.selectedTribeId = chat.getObjectId()
                    vc.listViewController?.setActiveTab(.tribes)
                } else {
                    vc.contactsService.selectedFriendId = chat.getObjectId()
                    vc.listViewController?.setActiveTab(.friends)
                }
                
                vc.shouldGoToChat(chatId: chat.id)
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
            vc.processContentDeeplink(n: n)
        }
        
        NotificationCenter.default.addObserver(forName: .onShareContactDeeplink, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            vc.processContactDeepLink(n: n)
        }
        
        NotificationCenter.default.addObserver(forName: .webViewImageClicked, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            vc.handleImageNotification(n: n)
        }
    }
    
    func processContactDeepLink(n: Notification){
        if let query = n.userInfo?["query"] as? String,
           let pubkey = query.getLinkValueFor(key: "pubKey") {
            let userInfo: [String: Any] = ["pub-key" : pubkey]
            NotificationCenter.default.post(name: .onPubKeyClick, object: nil, userInfo: userInfo)
        }
    }
    
    func processContentDeeplink(n: Notification){
        var success = false
        
        if let query = n.userInfo?["query"] as? String,
           let feedID = query.getLinkValueFor(key: "feedID"),
           let itemID = query.getLinkValueFor(key: "itemID"){
            print(query)
            
            if let feed = ContentFeed.getFeedById(feedId: feedID),
               let chat = feed.chat {
                let timestamp = query.getLinkValueFor(key: "atTime")
                let finalTS = Int(timestamp ?? "") ?? 0
                
                self.deeplinkData = DeeplinkData(
                    feedID: feedID,
                    itemID: itemID,
                    timestamp: finalTS
                )
                
                self.didClickOnChatRow(
                    chatId: chat.id,
                    contactId: nil
                )
                
                success = true
            }
        }
        if success == false{
            //throw error
            print("Error opening content deeplink")
            AlertHelper.showAlert(title: "deeplink.issue.title".localized, message: "deeplink.issue.message".localized)
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
    
    func handleImageNotification(n: Notification) {
        if let imageURL = n.userInfo?["image_url"] as? URL,
           let messageId = n.userInfo?["message_id"] as? Int,
           let message = TransactionMessage.getMessageWith(id: messageId) {
            
            goToMediaFullView(imageURL: imageURL,message: message)
        } else {
            NewMessageBubbleHelper().showGenericMessageView(text: "Error pulling image data.")
        }
    }
    
    func goToMediaFullView(
        imageURL: URL,
        message: TransactionMessage
    ){
        if mediaFullScreenView == nil {
            mediaFullScreenView = MediaFullScreenView()
        }

        if let mediaFullScreenView = mediaFullScreenView {
            view.addSubview(mediaFullScreenView)
            
            mediaFullScreenView.showWith(imageURL: imageURL, message: message,completion: {
                mediaFullScreenView.delegate = self
                mediaFullScreenView.constraintTo(view: self.view)
                mediaFullScreenView.currentMode = MediaFullScreenView.ViewMode.Viewing
                mediaFullScreenView.loading = false
                mediaFullScreenView.mediaImageView.alphaValue = 1.0
                mediaFullScreenView.mediaImageView.gravity = .resizeAspect
            })
            mediaFullScreenView.isHidden = false
        }
    }
    
    func shouldGoToChat(chatId: Int) {
        self.listViewController?.selectRowFor(chatId: chatId)
    }
    
    func reloadView() {
        self.listViewController?.contactChatsContainerViewController.forceReload()
        self.listViewController?.tribeChatsContainerViewController.forceReload()
        self.newDetailViewController?.forceReload()
    }
    
    func reloadData() {
        self.chatListViewModel.loadFriends { _ in

            self.chatListViewModel.syncMessages(
                chatId: self.newDetailViewController?.chat?.id,
                progressCallback: { (_, _) in }
            ) { (_, _) in

                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    appDelegate.setBadge(count: TransactionMessage.getReceivedUnseenMessagesCount())
                }
            }
        }
    }
    
    func addEscapeMonitor() {
        //add event monitor in case user never clicks the textfield
        if let escapeMonitor = escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
        }
    
        escapeMonitor = nil
    
        self.escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) in
            if event.keyCode == 53 { // 53 is the key code for the Escape key
                // Perform your action when the Escape key is pressed
                if self.mediaFullScreenView?.isHidden == false {
                    self.mediaFullScreenView?.closeView()
                    return nil
                ///Hide dashboard views popups (Profile, Create Tribe, etc)
                } else if !self.presenterContainerBGView.isHidden {
                    WindowsManager.sharedInstance.dismissViewFromCurrentWindow()
                    return nil
                ///Hide modals (auth, etc)
                } else if !self.modalsContainerView.isHidden {
                    for childVC in self.children {
                        if let childVC = childVC as? DashboardModalsViewController {
                            childVC.shouldDismissModals()
                        }
                    }
                ///Hide chat modals (send payment, calls, etc)
                } else if self.newDetailViewController?.hideModals() == true {
                    return nil
                ///Hide right panel view
                } else if !self.rightDetailSplittedView.isHidden {
                    self.dashboardDetailViewController?.closeButtonTapped()
                    return nil
                }
            }
            return event
        }
    }
}

extension DashboardViewController : NSSplitViewDelegate {
    func splitViewDidResizeSubviews(_ notification: Notification) {
        if let _ = view.window {
            resizeSubviews()

            resizeTimer?.invalidate()
            resizeTimer = Timer.scheduledTimer(
                timeInterval: 0.05,
                target: self,
                selector: #selector(resizeSubviews),
                userInfo: nil,
                repeats: false
            )
        }
    }

    @objc func resizeSubviews() {
        newDetailViewController?.resizeSubviews(frame: rightSplittedView.bounds)
        dashboardDetailViewController?.resizeSubviews(frame: rightDetailSplittedView.bounds)
        listViewController?.menuListView.menuDataSource?.updateFrame()
        
        listViewController?.view.frame = leftSplittedView.bounds
        dashboardDetailViewController?.updateCurrentVCFrame()
    }
}

extension DashboardViewController : DashboardVCDelegate {
    func shouldResetContactView(deletedContactId: Int) {
        contactsService.selectedFriendId = nil
        
        didClickOnChatRow(
            chatId: nil,
            contactId: nil
        )
    }
    
    func shouldResetTribeView() {
        contactsService.selectedTribeId = nil
        
        didClickOnChatRow(
            chatId: nil,
            contactId: nil
        )
    }
    
    func didSwitchToTab() {
        let (chatId, contactId) = contactsService.getObjectIdForCurrentSelection()
        
        if let chatId = chatId {
            didClickOnChatRow(
                chatId: chatId,
                contactId: nil
            )
        } else if let contactId = contactId {
            didClickOnChatRow(
                chatId: nil,
                contactId: contactId
            )
        }
    }
    
    func didClickOnChatRow(
        chatId: Int?,
        contactId: Int?
    ) {
        if let contactId = contactId, let contact = UserContact.getContactWith(id: contactId), contact.isPending() {
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
            self.presentChatVCFor(
                chatId: chatId,
                contactId: contactId
            )
        }
    }
    
    func payInvite(invite: UserInvite) {
        AlertHelper.showTwoOptionsAlert(title: "pay.invitation".localized, message: "", confirm: {
            self.chatListViewModel.payInvite(invite: invite, completion: { contact in
                if contact == nil {
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
    
    func reloadChatListVC() {
        if let listViewController = listViewController {
            self.removeChildVC(child: listViewController)
        }
        
        let chatListVCController = ChatListViewController.instantiate(
            delegate: self
        )
        
        self.addChildVC(
            child: chatListVCController,
            container: leftSplittedView
        )
        
        listViewController = chatListVCController        
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            ContactsService.sharedInstance.forceUpdate()
        })
    }
    
    func presentChatVCFor(
        chatId: Int?,
        contactId: Int?
    ) {
        if let chatId = chatId, newDetailViewController?.chat?.id == chatId {
            return
        }
        
        if let contactId = contactId, newDetailViewController?.contact?.id == contactId {
            return
        }
        
        if let detailViewController = newDetailViewController {
            detailViewController.resetVC()
            
            self.removeChildVC(child: detailViewController)
            
            newDetailViewController = nil
        }
        
        let chat = chatId != nil ? Chat.getChatWith(id: chatId!) : nil
        let contact = contactId != nil ? UserContact.getContactWith(id: contactId!) : chat?.getConversationContact()
        
        let newChatVCController = NewChatViewController.instantiate(
            contactId: contact?.id,
            chatId: chat?.id,
            delegate: self,
            deepLinkData: deeplinkData
        )
        
        self.addChildVC(
            child: newChatVCController,
            container: rightSplittedView
        )
        dashboardDetailViewController?.closeButtonTapped()
        
        newDetailViewController = newChatVCController
        newDetailViewController?.setMessageFieldActive()

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
    
    @objc func handleImageNotification(_ notification: Notification) {
        if let imageURL = notification.userInfo?["imageURL"] as? URL,
           let message = notification.userInfo?["transactionMessage"] as? TransactionMessage {
            goToMediaFullView(imageURL: imageURL,message: message)
        } else {
            NewMessageBubbleHelper().showGenericMessageView(text: "Error pulling image data.")
        }
    }
    
    func shouldToggleLeftView(show: Bool?) {
        if let window = view.window {
            let menuVisible = show ?? !isLeftMenuCollapsed()
            newDetailViewController?.toggleExpandMenuButton(show: !menuVisible)
            let (minWidth, _) = getWindowMinWidth(leftColumnVisible: menuVisible)
            leftSplittedView.isHidden = !menuVisible
            window.minSize = CGSize(width: minWidth, height: kWindowMinHeight)

            let newWidth = menuVisible ? max(window.frame.width, minWidth) : window.frame.width
            let newFrame = CGRect(x: window.frame.origin.x, y: window.frame.origin.y, width: newWidth, height: window.frame.height)
            window.setFrame(newFrame, display: true)
        }
    }

    func isLeftMenuCollapsed() -> Bool {
        return leftSplittedView.isHidden
    }

    func getWindowMinWidth(leftColumnVisible: Bool) -> (CGFloat, CGFloat) {
        let podcastPlayerWidth =  newDetailViewController?.podcastPlayerView.frame.width ?? 0
        let leftPanelWidth = leftSplittedView.frame.width
        let minWidth: CGFloat = leftColumnVisible ? kWindowMinWidthWithoutLeftColumn + leftPanelWidth : kWindowMinWidthWithoutLeftColumn
        return (minWidth + podcastPlayerWidth, leftPanelWidth)
    }
    
    func shouldShowRestoreModal(
        with progress: Int,
        label: String,
        buttonEnabled: Bool
    ) {
        for childVC in self.children {
            if let childVC = childVC as? DashboardModalsViewController {
                modalsContainerView.isHidden = false
                
                childVC.showProgressViewWith(
                    with: progress,
                    label: label,
                    buttonEnabled: buttonEnabled,
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
    func shouldShowAlert(message: String) {
        listViewController?.shouldShowAlert(message: message)
    }
    
    func didUpdateChatFromMessage(_ chat: Chat) {
        newDetailViewController?.didUpdateChatFromMessage(chat)
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
        
        listViewController?.finishLoading()
    }
}

extension DashboardViewController: NewContactDismissDelegate {
    func shouldDismissView() {
        closePresenter()
    }
}

extension DashboardViewController: DashboardDetailDismissDelegate {
    func closeButtonTapped() {
        rightDetailViewMaxWidth.constant = 0
        rightDetailSplittedView.isHidden = true
        
        newDetailViewController?.chatBottomView.messageFieldView.isThreadOpen = false
        newDetailViewController?.chatBottomView.messageFieldView.updatePriceTagField()
    }
}
