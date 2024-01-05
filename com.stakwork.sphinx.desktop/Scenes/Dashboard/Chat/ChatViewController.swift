//
//  ChatViewController.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import CoreData

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
    
    var currentMessageString = ""
    var unseenMessagesCount = 0
    
    let kCharacterLimit = 500
    let kBottomBarMargins:CGFloat = 41
    
    let kMinimumPriceFieldWidth: CGFloat = 50
    let kPriceFieldPadding: CGFloat = 10
    
    var contact: UserContact?
    var chat: Chat?
    var chatDataSource : ChatDataSource? = nil
    
    var replyableMessages: [TransactionMessage] = []
    
    var audioRecorderHelper = AudioRecorderHelper()
    let attachmentsManager = AttachmentsManager.sharedInstance
    var messageOptionsHelper = MessageOptionsHelper.sharedInstance
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    var podcastPlayerHelper: PodcastPlayerHelper? = nil
    var podcastPlayerVC: NewPodcastPlayerViewController? = nil
    
    public enum RecordingButton: Int {
        case Confirm
        case Cancel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        prepareRecordingView()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        chatDataSource?.setDelegates(self)
        
        NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: chatCollectionView.enclosingScrollView?.contentView, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.chatDataSource?.scrollViewDidScroll()
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: nil)
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
        
        messageTextView.string = ""
        chatCollectionView.alphaValue = 0.0
        let _ = updateBottomBarHeight()
        
        self.contact = contact
        self.chat = chat
        self.contactsService = contactsService
        
        if chat == nil && contact == nil {
            childVCContainer.resetAllViews()
            resetHeader()
            return
        }
        
        podcastPlayerHelper = nil
        
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
        checkRoute()
    }
    
    func setChatInfo() {
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
        let replyableMessage = replyableMessages.filter { $0.chat?.id == chat?.id }.first
        
        if replyableMessage != Optional.none {
            updateMessageReplyView(message: replyableMessage!) 
        } else {
            hideMessageReplyView()
        }
        
        hideGiphySearchView()
        chatDataSource?.setDataAndReload(contact: contact, chat: chat, forceReload: forceReload)
        chatCollectionView.scrollToBottom(animated: false)
        updateTribeInfo()
        setMessagesAsSeen()
    }
    
    func reload() {
        DispatchQueue.global().async {
            self.chatListViewModel.syncMessages(chatId: self.chat?.id, progressCallback: { _ in }) { (newChatMessageCount, _) in
                DispatchQueue.main.async {
                    self.reloadMessages(newMessageCount: newChatMessageCount)
                }
            }
        }
    }
    
    func reloadMessages(newMessageCount: Int = 0) {
        setMessagesAsSeen()
        reloadAndScroll(newMessageCount: newMessageCount)
    }
    
    func updateTribeInfo() {
        checkActiveTribe()
        removePodcastVC()
        
        chat?.updateTribeInfo() {
            self.setChatInfo()
            self.loadPodcastFeed()
            
            WindowsManager.sharedInstance.showWebAppWindow(chat: self.chat, view: self.view)
        }
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
    }
    
    func reloadAndScroll(newMessageCount: Int = 0) {
        if newMessageCount > 0 {
            chatDataSource?.setDataAndReload(contact: contact, chat: chat)
            chatCollectionView.scrollToBottom(animated: false)
        }
    }
    
    func shouldScrollToBottom(provisional: Bool = false) {
        if chatCollectionView.shouldScrollToBottom() || provisional {
            chatCollectionView.scrollToBottom(animated: !provisional)
        } else {
            unseenMessagesCount = unseenMessagesCount + 1
            scrollDownLabel.stringValue = "+\(unseenMessagesCount)"
            scrollDownContainer.isHidden = false
        }
    }
    
    func setVolumeState() {
        volumeButton.image = NSImage(named: chat?.isMuted() ?? false ? "muteOnIcon" : "muteOffIcon")
    }
    
    func loadPodcastFeed() {
        guard let chat = self.chat, let feedUrl = chat.tribesInfo?.feedUrl, !feedUrl.isEmpty else {
            return
        }
        if podcastPlayerHelper == nil {
            podcastPlayerHelper = chat.getPodcastPlayer()
        }
        podcastPlayerHelper?.loadPodcastFeed(chat: self.chat, callback: { (success, chatId) in
            if let _ = chat.podcastPlayer?.podcast, success && chatId == self.chat?.id {
                self.addPodcastVC()
                self.updateSatsEarned()
            }
        })
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
        replyableMessages.removeAll(where: { $0.chat?.id == chat?.id})
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
    
    @IBAction func giphyButtonClicked(_ sender: Any) {
        bottomBar.removeShadow()
        giphySearchView.loadGiphySearch(delegate: self)
        toggleGiphySearchView()
    }
    
    @IBAction func volumeButtonClicked(_ sender: Any) {
        guard let chat = chat else {
            return
        }
        
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
