//
//  ChatViewController.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import CoreData
import WebKit

class ChatViewController: DashboardSplittedViewController {
    
    @IBOutlet weak var headerView: NSView!
    @IBOutlet weak var chatAvatarView: ChatAvatarView!
    @IBOutlet weak var nameButton: NSButton!
    @IBOutlet weak var nameButtonY: NSLayoutConstraint!
    @IBOutlet weak var pricePerMessageLabel: NSTextField!
    @IBOutlet weak var contributedSatsLabel: NSTextField!
    @IBOutlet weak var contributedSatsIcon: NSTextField!
    @IBOutlet weak var healthCheckSign: NSTextField!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var webAppButton: CustomButton!
    @IBOutlet weak var volumeButton: CustomButton!
    @IBOutlet weak var videoCallButton: CustomButton!
    @IBOutlet weak var expandMenuButton: NSButton!
    
    @IBOutlet weak var messageFieldContainer: NSView!
    @IBOutlet var messageTextView: PlaceHolderTextView!
    
    @IBOutlet weak var bottomBar: NSView!
    @IBOutlet weak var attachmentsButton: CustomButton!
    @IBOutlet weak var sendButton: CustomButton!
    @IBOutlet weak var micButton: CustomButton!
    @IBOutlet weak var emojiButton: CustomButton!
    @IBOutlet weak var giphyButton: CustomButton!
    
    @IBOutlet weak var priceContainer: NSBox!
    @IBOutlet weak var priceTextField: CCTextField!
    @IBOutlet weak var priceTextFieldWidth: NSLayoutConstraint!
    
    @IBOutlet weak var recordingContainer: NSBox!
    @IBOutlet weak var recordingRedCircle: IntermitentAlphaAnimatedView!
    @IBOutlet weak var recordingTimeLabel: NSTextField!
    @IBOutlet weak var recordingConfirmButtonContainer: NSBox!
    @IBOutlet weak var recordingCancelButtonContainer: NSBox!
    
    @IBOutlet weak var chatCollectionView: NSCollectionView!
    @IBOutlet weak var draggingView: DraggingDestinationView!
    @IBOutlet weak var childVCContainer: ChildVCContainer!
    @IBOutlet weak var podcastVCContainer: NSView!
    @IBOutlet weak var podcastContainerWidth: NSLayoutConstraint!
    
    @IBOutlet weak var messageReplyView: MessageReplyView!
    @IBOutlet weak var messageReplyViewHeight: NSLayoutConstraint!
    @IBOutlet weak var giphySearchView: GiphySearchView!
    @IBOutlet weak var searchTopView: NSView!
    @IBOutlet weak var searchTopViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var scrollDownContainer: NSView!
    @IBOutlet weak var scrollDownLabel: NSTextField!
    
    @IBOutlet weak var avatarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomBarHeightConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var mentionScrollViewHeight: NSLayoutConstraint!
    
    
    @IBOutlet weak var mentionAutoCompleteEnclosingScrollView: NSScrollView!
    @IBOutlet weak var mentionAutoCompleteTableView: NSCollectionView!
    var chatMentionAutocompleteDataSource : ChatMentionAutocompleteDataSource? = nil
    
    var currentMessageString = ""
    
    var unseenMessagesCount = 0
    
    var codePreview : CodeWebView? = nil
    
    var unseenMessagesCountLabel: String {
        get {
            if unseenMessagesCount > 0 {
                return "+\(unseenMessagesCount)"
            } else {
                return ""
            }
        }
    }
    
    let kCharacterLimit = 500
    let kBottomBarMargins:CGFloat = 41
    
    let kMinimumPriceFieldWidth: CGFloat = 50
    let kPriceFieldPadding: CGFloat = 10
    
    var contact: UserContact?
    
    var chat: Chat? = nil {
        willSet{
            if (chat?.id != newValue?.id) {
                trackChatScrollPosition()
            }
        }
    }
    
    var chatDataSource : ChatDataSource? = nil
    
    var audioRecorderHelper = AudioRecorderHelper()
    let attachmentsManager = AttachmentsManager.sharedInstance
    var messageOptionsHelper = MessageOptionsHelper.sharedInstance
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    var podcastPlayerVC: NewPodcastPlayerViewController? = nil
    
    
    public enum RecordingButton: Int {
        case Confirm
        case Cancel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mentionAutoCompleteEnclosingScrollView.isHidden = true
        configureView()
        prepareRecordingView()
    }
    
    func showCodePreviewWV(codeString:String){
        codePreview = CodeWebView(frame: messageTextView.frame)
        
        codePreview?.loadHTMLString(codeString, baseURL: nil)
        if let preview = codePreview{
            self.messageTextView.addSubview(preview)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        chatDataSource?.setDelegates(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.setChatInfo), name: .shouldReloadTribeData, object: nil)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        NotificationCenter.default.removeObserver(self, name: .shouldReloadTribeData, object: nil)
        chatDataSource?.setDelegates(nil)
    }
    
    override func viewDidLayout() {
        let _ = updateBottomBarHeight()
        chatDataSource?.updateFrame()
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.Sphinx.HeaderBG.cgColor
    }
    
    func configureView() {
        headerView.addShadow(location: VerticalLocation.bottom, color: NSColor.black, opacity: 0.2, radius: 5.0)
        
        scrollDownContainer.wantsLayer = true
        scrollDownContainer.layer?.backgroundColor = NSColor.Sphinx.PrimaryGreen.cgColor
        scrollDownContainer.layer?.cornerRadius = 10
        scrollDownContainer.addShadow(location: .center, opacity: 0.3, radius: 3, cornerRadius: 10)
        scrollDownContainer.isHidden = true
        
        expandMenuButton.wantsLayer = true
        expandMenuButton.layer?.backgroundColor = NSColor.Sphinx.PrimaryBlue.cgColor
        expandMenuButton.layer?.cornerRadius = 5
        expandMenuButton.addShadow(location: VerticalLocation.center, color: NSColor.Sphinx.PrimaryGreen, opacity: 0.2, radius: 5, cornerRadius: 5)
        
        configureTopAndBottomBar()
    }
    
    func configureTopAndBottomBar() {
        volumeButton.cursor = .pointingHand
        videoCallButton.cursor = .pointingHand
        attachmentsButton.cursor = .pointingHand
        webAppButton.cursor = .pointingHand
        
        bottomBar.addShadow(location: VerticalLocation.top, color: NSColor.black, opacity: 0.3, radius: 5.0)
        searchTopView.addShadow(location: VerticalLocation.top, color: NSColor.black, opacity: 0.3, radius: 5.0)
        
        priceContainer.wantsLayer = true
        priceContainer.layer?.cornerRadius = priceContainer.frame.height / 2
        
        priceTextField.color = NSColor.Sphinx.Body
        priceTextField.formatter = IntegerValueFormatter()
        priceTextField.delegate = self
        priceTextField.isEditable = false
        
        attachmentsButton.wantsLayer = true
        attachmentsButton.layer?.cornerRadius = attachmentsButton.frame.height / 2
        attachmentsButton.layer?.backgroundColor = NSColor.Sphinx.PrimaryBlue.cgColor
        attachmentsButton.isEnabled = false
        
        sendButton.wantsLayer = true
        sendButton.layer?.cornerRadius = sendButton.frame.height / 2
        sendButton.layer?.backgroundColor = NSColor.Sphinx.PrimaryBlue.cgColor
        sendButton.isEnabled = false
        sendButton.cursor = .pointingHand
        
        toggleRecordButton(enable: false)
        toggleControls(enable: false)
        
        messageFieldContainer.wantsLayer = true
        messageFieldContainer.layer?.cornerRadius = messageFieldContainer.frame.height / 2
        messageTextView.isEditable = false
        messageTextView.setPlaceHolder(color: NSColor.Sphinx.PlaceholderText, font: NSFont(name: "Roboto-Regular", size: 16.0)!, string: "message.placeholder".localized)
        messageTextView.font = NSFont(name: "Roboto-Regular", size: 16.0)!
        messageTextView.delegate = self
        messageTextView.fieldDelegate = self
        
        chatCollectionView.enclosingScrollView?.contentView.postsBoundsChangedNotifications = true
    }
    
    func configureMentionAutocompleteTableView(){
        mentionAutoCompleteTableView.isHidden = false
        chatMentionAutocompleteDataSource = ChatMentionAutocompleteDataSource(tableView: mentionAutoCompleteTableView, scrollView: mentionAutoCompleteEnclosingScrollView,delegate:self, vc: self)
        mentionAutoCompleteTableView.delegate = chatMentionAutocompleteDataSource
        mentionAutoCompleteTableView.dataSource = chatMentionAutocompleteDataSource
       
        chatMentionAutocompleteDataSource?.updateMentionSuggestions(suggestions: [])
    }
    
    func resetHeader() {
        toggleRecordButton(enable: false)
        toggleControls(enable: false)
        chatAvatarView.setImages(object: nil)
        
        nameButton.title = "open.conversation".localized
        avatarWidthConstraint.constant = 20
        nameButtonY.constant = 0
        pricePerMessageLabel.stringValue = ""
        headerView.layoutSubtreeIfNeeded()
        lockSign.stringValue = ""
        
        healthCheckSign.isHidden = true
        volumeButton.isHidden = true
        webAppButton.isHidden = true
        videoCallButton.isHidden = true
        contributedSatsIcon.isHidden = true
        contributedSatsLabel.isHidden = true
    }
    
    func toggleExpandMenuButton(show: Bool) {
        expandMenuButton.isHidden = !show
    }
    
    func loadChatFor(contact: UserContact? = nil, chat: Chat? = nil, contactsService: ContactsService) {        
        if let chat = chat, let viewChat = self.chat, chat.id == viewChat.id {
            return
        }
        
        resetHeader()
        
        messageTextView.string = ""
        chatCollectionView.alphaValue = 0.0
        let _ = updateBottomBarHeight()
        
        self.contact = contact
        self.chat = chat
        self.chat?.loadAllAliases()
        
        self.contactsService = contactsService
        
        if chat == nil && contact == nil {
            childVCContainer.resetAllViews()
            return
        }
        
        contributedSatsIcon.isHidden = true
        contributedSatsLabel.isHidden = true
        healthCheckSign.isHidden = false
        lockSign.isHidden = false
        volumeButton.isHidden = false
        videoCallButton.isHidden = false
        view.window?.makeFirstResponder(messageTextView)
        
        toggleRecordButton(enable: !audioRecorderHelper.isPermissionDenied())
        toggleControls(enable: chat?.isStatusApproved() ?? true)
        setChatInfo()
        
        if chatDataSource == nil {
            chatDataSource = ChatDataSource(collectionView: chatCollectionView, delegate: self, cellDelegate: self)
        }
        initialLoad()
        updateTribeInfo()
        checkActiveTribe()
        checkRoute()
    }
    
    @objc func setChatInfo() {
        avatarWidthConstraint.constant = 75
        headerView.layoutSubtreeIfNeeded()
        
        nameButton.title = "name.unknown".localized
        
        if let chat = chat, chat.isGroup() {
            nameButton.title = chat.getName()
        } else if let contact = contact {
            nameButton.title = contact.getName()
        }
        
        chatAvatarView.setImages(object: contact ?? chat)
        
        let isEncrypted = (chat?.isEncrypted() ?? contact?.hasEncryptionKey()) ?? false
        lockSign.stringValue = isEncrypted ? "lock" : "lock_open"
        
        updateTribePrices()
        toggleControls(enable: chat?.isStatusApproved() ?? true)
        setVolumeState()
        draggingView.setup()
        childVCContainer.resetAllViews()
        
        messageTextView.string = chat?.ongoingMessage ?? ""
        let _ = updateBottomBarHeight()
        
        if let contact = contact, !contact.hasEncryptionKey() {
            forceKeysExchange(contactId: contact.id)
        }
    }
    
    func initialLoad(forceReload: Bool = false) {
        hideMessageReplyView()
        hideGiphySearchView()
        
        chatDataSource?.setDataAndReload(
            contact: contact,
            chat: chat,
            forceReload: forceReload
        )
        
        unseenMessagesCount = chatDataSource?.getUnseenMessagesCount() ?? 0
        
        scrollToPreviuosPosition()
    }
    
    func scrollToPreviuosPosition() {
        scrollDownContainer.isHidden = true
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.2, completion: {
            if let chat = self.chat,
               let tablePosition = GroupsManager.sharedInstance.getChatLastRead(chatID: chat.id) {
                
                self.chatCollectionView.scrollToOffset(yPosition: tablePosition.1)
                
                let isPositionAtBottom = self.chatCollectionView.isClosedToBottom(yPosition: tablePosition.1)
                
                self.scrollDownLabel.stringValue = self.unseenMessagesCountLabel
                self.scrollDownContainer.isHidden = isPositionAtBottom
                
                if isPositionAtBottom { self.setMessagesAsSeen() }
            } else {
                self.chatCollectionView.scrollToBottom(animated: false)
                self.setMessagesAsSeen()
            }
            
            self.didFinishLoading()
        })
    }
    
    func reload() {
        DispatchQueue.global().async {
            self.chatListViewModel.syncMessages(chatId: self.chat?.id, progressCallback: { (_, _) in }) { (newChatMessageCount, _) in
                DispatchQueue.main.async {
                    self.reloadMessages(newMessageCount: newChatMessageCount)
                }
            }
        }
    }
    
    func reloadMessages(newMessageCount: Int = 0) {
        reloadAndScroll(newMessageCount: newMessageCount)
    }
    
    func updateTribeInfo() {
        removePodcastVC()
        
        guard let chat = chat else {
            return
        }
        
        if let feedId = chat.contentFeed?.feedID, PodcastPlayerController.sharedInstance.isPlaying(podcastId: feedId) {
            self.onTribeInfoUpdated()
            FeedsManager.sharedInstance.restoreContentFeedStatusInBackgroundFor(feedId: feedId)
            return
        }
        
        chat.updateTribeInfo() {
            self.onTribeInfoUpdated()
        }
    }
    
    private func onTribeInfoUpdated() {
        setChatInfo()
        webAppButton.isHidden = !(chat?.hasWebApp() ?? false)
        addPodcastVC()
        updateSatsEarned()
    }
    
    func updateTribePrices() {
        if chat?.shouldShowPrice() ?? false {
            if let prices = chat?.getTribePrices() {
                self.nameButtonY.constant = -8
                self.pricePerMessageLabel.stringValue = String(format: "group.price.text".localized, "\(prices.0)", "\(prices.1)")
            }
        } else {
            self.nameButtonY.constant = 0
            self.pricePerMessageLabel.stringValue = ""
        }
    }
    
    func checkActiveTribe() {
        let pending = chat?.isStatusPending() ?? false
        let active = chat?.isStatusApproved() ?? true
        
        toggleRecordButton(enable: active)
        toggleControls(enable: active)
        
        if pending {
            messageBubbleHelper.showGenericMessageView(text: "waiting.admin.approval".localized, in: self.view, position: .Top)
        }
    }
    
    func setMessagesAsSeen(forceSeen: Bool = false) {
        chat?.setChatMessagesAsSeen(forceSeen: forceSeen)
        
        unseenMessagesCount = 0
        scrollDownLabel.stringValue = unseenMessagesCountLabel
        scrollDownContainer.isHidden = true
        
        NotificationCenter.default.post(name: .shouldReloadChatsList, object: nil)
    }
    
    func reloadAndScroll(newMessageCount: Int = 0) {
        if newMessageCount > 0 {
            chatDataSource?.setDataAndReload(contact: contact, chat: chat)
            chatCollectionView.scrollToBottom(animated: false)
        }
    }
    
    func shouldScrollToBottom(force: Bool = false) {
        if chatCollectionView.shouldScrollToBottom() || force {
            chatCollectionView.scrollToBottom(animated: !force)
        } else {
            unseenMessagesCount = unseenMessagesCount + 1
            scrollDownLabel.stringValue = unseenMessagesCountLabel
            scrollDownContainer.isHidden = false
        }
    }
    
    func setVolumeState() {
        volumeButton.image = NSImage(named: chat?.isMuted() ?? false ? "muteOnIcon" : "muteOffIcon")
    }
    
    func checkRoute() {
        healthCheckSign.textColor = NSColor.Sphinx.SecondaryText
        
        API.sharedInstance.checkRoute(chat: self.chat, contact: self.contact, callback: { success in
            DispatchQueue.main.async {
                self.healthCheckSign.textColor = success ? HealthCheckView.kConnectedColor : HealthCheckView.kNotConnectedColor
            }
        })
    }
    
    @IBAction func expandMenuButtonClicked(_ sender: Any) {
        delegate?.shouldToggleLeftView(show: true)
    }
    
    @IBAction func recordingButtonClicked(_ sender: Any) {
        if let sender = sender as? NSButton {
            didClickRecordingButton(sender)
        }
    }
    
    @IBAction func sendMessageButtonTouched(_ sender: Any) {
        shouldSendMessage()
    }
    
    @IBAction func micButtonClicked(_ sender: Any) {
        shouldStartRecording()
    }
    
    @IBAction func attachmentButtonClicked(_ sender: Any) {
        hideMessageReplyView()
        
        if (chat?.isPublicGroup() ?? false) {
            messageBubbleHelper.showGenericMessageView(text: "drag.attachment".localized, in: view, delay: 2.5)
        } else {
            messageTextView.window?.makeFirstResponder(nil)
            childVCContainer.showPmtOptionsMenuOn(parentVC: self, with: self.chat, delegate: self)
        }
    }
    
    @IBAction func emojiButtonClicked(_ sender: Any) {
        NSApp.orderFrontCharacterPalette(textView)
        view.window?.makeFirstResponder(messageTextView)
    }
    
    
    @IBAction func codeButtonClicked(_ sender: Any) {
        print("codeButtonClicked")
        bottomBarHeightConstraint.constant = self.view.frame.height/2.0
        let segmentedControl = NSSegmentedControl(frame: NSRect(origin: CGPoint(x: self.view.frame.width * 0.4, y: self.view.frame.height * 0.51), size: CGSize(width: self.view.frame.width * 0.2, height: self.view.frame.height * 0.05)))
        segmentedControl.segmentCount = 2
        segmentedControl.setLabel("Editor", forSegment: 0)
        segmentedControl.setLabel("Preview", forSegment: 1)
        segmentedControl.alphaValue = 1.0
        segmentedControl.selectedSegment = 0
        segmentedControl.action = #selector(previewSegmentSelected(_:))
        self.view.addSubview(segmentedControl)
        self.view.bringSubviewToFront(segmentedControl)
        segmentedControl.layer?.zPosition = 1000
        self.view.layoutSubtreeIfNeeded()
    }
    
    @objc func previewSegmentSelected(_ sender: NSSegmentedControl){
        if sender.selectedSegment == 0{
            hideCodePreview()
        }
        else if sender.selectedSegment == 1{
            showCodePreview()
        }
    }
    
    @objc func hideCodePreview(){
        codePreview?.removeFromSuperview()
        codePreview = nil
    }
    
    @objc func showCodePreview(){
        showCodePreviewWV(codeString: messageTextView.string)
    }
    
    
    @IBAction func giphyButtonClicked(_ sender: Any) {
        bottomBar.removeShadow()
        giphySearchView.loadGiphySearch(delegate: self)
        toggleGiphySearchView()
    }
    
    @IBAction func webAppButtonClicked(_ sender: Any) {
        WindowsManager.sharedInstance.showWebAppWindow(chat: self.chat, view: self.view)
    }
    
    @IBAction func volumeButtonClicked(_ sender: Any) {
        guard let chat = chat else {
            return
        }

        if chat.isPublicGroup() {
            childVCContainer.showNotificaionLevelViewOn(parentVC: self, with: chat, delegate: self)
        } else {
            volumeButton.image = NSImage(named: !chat.isMuted() ? "muteOnIcon" : "muteOffIcon")

            chatViewModel.toggleVolumeOn(chat: chat, completion: { chat in
                if let chat = chat {
                    if chat.isMuted() {
                        self.messageBubbleHelper.showGenericMessageView(text: "chat.muted.message".localized, in: self.view, delay: 2.5)
                    }
                }
                self.setChatInfo()
                self.setVolumeState()
                self.delegate?.shouldReloadChatList()
            })
        }
    }
    
    func exitAndDeleteGroup(completion: @escaping () -> ()) {
        let isPublicGroup = chat?.isPublicGroup() ?? false
        let isMyPublicGroup = chat?.isMyPublicGroup() ?? false
        let deleteLabel = (isPublicGroup ? "delete.tribe" : "delete.group").localized
        let confirmDeleteLabel = (isMyPublicGroup ? "confirm.delete.tribe" : (isPublicGroup ? "confirm.exit.delete.tribe" : "confirm.exit.delete.group")).localized
        
        AlertHelper.showTwoOptionsAlert(title: deleteLabel, message: confirmDeleteLabel, confirm: {
            GroupsManager.sharedInstance.deleteGroup(chat: self.chat, completion: { success in
                if success {
                    self.didDeleteGroup()
                    completion()
                } else {
                    AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
                }
            })
        })
    }
    
    @IBAction func scrollDownButtonClicked(_ sender: Any) {
        chatCollectionView.scrollToBottom()
    }
    
    @IBAction func videoCallButtonClicked(_ sender: Any) {
        messageTextView.window?.makeFirstResponder(nil)
        childVCContainer.showCallOptionsMenuOn(parentVC: self, with: self.chat, delegate: self)
    }
    
    @IBAction func nameButtonClicked(_ sender: Any) {
        if let contact = contact {
            let contactVC = NewContactViewController.instantiate(contactsService: contactsService, contact: contact)
            WindowsManager.sharedInstance.showContactWindow(vc: contactVC, window: view.window, title: "add.friend".localized, identifier: "contact-window", size: CGSize(width: 414, height: 700))
        } else if let chat = chat {
            let chatDetailsVC = GroupDetailsViewController.instantiate(chat: chat, delegate: self)
            WindowsManager.sharedInstance.showContactWindow(vc: chatDetailsVC, window: view.window, title: "group.details".localized, identifier: "chat-window", size: CGSize(width: 414, height: 600))
        }
    }
}
