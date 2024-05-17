//
//  ChatMessageFieldView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 07/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ChatMessageFieldView: NSView, LoadableNib {
    
    weak var delegate: ChatBottomViewDelegate?

    @IBOutlet var contentView: NSView!
    
    @IBOutlet var messageTextView: PlaceHolderTextView!
    @IBOutlet weak var messageTextViewContainer: NSBox!
    
    @IBOutlet weak var attachmentsButton: CustomButton!
    @IBOutlet weak var sendButton: CustomButton!
    @IBOutlet weak var micButton: CustomButton!
    @IBOutlet weak var emojiButton: CustomButton!
    @IBOutlet weak var giphyButton: CustomButton!
    
    @IBOutlet weak var priceContainer: NSBox!
    @IBOutlet weak var priceTextField: CCTextField!
    @IBOutlet weak var priceTextFieldWidth: NSLayoutConstraint!
    
    @IBOutlet weak var recordingContainer: NSBox!
    @IBOutlet weak var intermitentAlphaView: IntermitentAlphaAnimatedView!
    @IBOutlet weak var recordingTimeLabel: NSTextField!
    
    @IBOutlet weak var messageContainerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var addDocumentCustomView: NSView!
    @IBOutlet weak var setPriceCustomView: NSBox!
    
    let kTextViewVerticalMargins: CGFloat = 41
    let kCharacterLimit = 1000
    let kTextViewLineHeight: CGFloat = 19
    let kMinimumPriceFieldWidth: CGFloat = 50
    let kPriceFieldPadding: CGFloat = 10
    
    let kFieldPlaceHolder = "message.placeholder".localized
    
    var macros : [MentionOrMacroItem] = []
    
    var chat: Chat? = nil
    var contact: UserContact? = nil
    var threadUUID: String? = nil
    
    
    var isThread: Bool {
        get {
            return threadUUID != nil
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setupView()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setupView()
    }
    
    func setupForThread() {
        addDocumentCustomView.isHidden = true
        setPriceCustomView.isHidden = true
    }
    
    func setupView() {
        setupButtonsCursor()
        setupMessageField()
        setupPriceField()
        setupAttachmentButton()
        setupSendButton()
        setupIntermitentAlphaView()
    }
    
    func setupIntermitentAlphaView() {
        intermitentAlphaView.configureForRecording()
    }
    
    func setupButtonsCursor() {
        attachmentsButton.cursor = .pointingHand
        sendButton.cursor = .pointingHand
        micButton.cursor = .pointingHand
        emojiButton.cursor = .pointingHand
        giphyButton.cursor = .pointingHand
    }
    
    func setupMessageField() {
        messageTextViewContainer.wantsLayer = true
        messageTextViewContainer.layer?.cornerRadius = messageTextViewContainer.frame.height / 2
        
        messageTextView.isEditable = true
        
        messageTextView.setPlaceHolder(
            color: NSColor.Sphinx.PlaceholderText,
            font: NSFont(name: "Roboto-Regular", size: 16.0)!,
            string: "message.placeholder".localized
        )
        
        messageTextView.font = NSFont(
            name: "Roboto-Regular",
            size: 16.0
        )!
        
        messageTextView.delegate = self
        messageTextView.fieldDelegate = self
    }
    
    func setupPriceField() {
        priceContainer.wantsLayer = true
        priceContainer.layer?.cornerRadius = priceContainer.frame.height / 2
        priceTextField.color = NSColor.Sphinx.SphinxWhite
        priceTextField.setColor(color: NSColor.Sphinx.SphinxWhite)
        priceTextField.formatter = IntegerValueFormatter()
        priceTextField.delegate = self
        priceTextField.isEditable = false
    }
    
    func setupAttachmentButton() {
        attachmentsButton.wantsLayer = true
        attachmentsButton.layer?.cornerRadius = attachmentsButton.frame.height / 2
        attachmentsButton.layer?.backgroundColor = NSColor.Sphinx.PrimaryBlue.cgColor
        attachmentsButton.isEnabled = false
    }
    
    func setupSendButton() {
        sendButton.wantsLayer = true
        sendButton.layer?.cornerRadius = sendButton.frame.height / 2
        sendButton.layer?.backgroundColor = NSColor.Sphinx.PrimaryBlue.cgColor
        sendButton.isEnabled = false
    }
    
    func updateBottomBarHeight() -> Bool {
        let isAtBottom = delegate?.isChatAtBottom() ?? false
        
        let messageFieldContentHeight = messageTextView.contentSize.height
        let updatedHeight = messageFieldContentHeight + kTextViewVerticalMargins
        let newFieldHeight = min(updatedHeight, kTextViewLineHeight * 6)
        
        if messageContainerHeightConstraint.constant == newFieldHeight {
            scrollMessageTextViewToBottom()
            return false
            
        }
        
        messageContainerHeightConstraint.constant = newFieldHeight
        layoutSubtreeIfNeeded()
        scrollMessageTextViewToBottom()
        
        if isAtBottom {
            delegate?.shouldScrollToBottom()
        }
        
        return true
    }
    
    func scrollMessageTextViewToBottom() {
        messageTextView.scrollRangeToVisible(
            NSMakeRange(
                messageTextView.string.length,
                0
            )
        )
    }
    
    func updateFieldStateFrom(
        _ chat: Chat?,
        contact: UserContact?,
        threadUUID: String?,
        with delegate: ChatBottomViewDelegate?
    ) {
        self.chat = chat
        self.contact = contact
        self.threadUUID = threadUUID
        self.delegate = delegate
        
        let pending = chat?.isStatusPending() ?? true
        let rejected = chat?.isStatusRejected() ?? true
        let active = (!pending && !rejected || (chat == nil && contact != nil))
        
        sendButton.isEnabled = active
        attachmentsButton.isEnabled = active
        priceTextField.isEditable = active && !isThread
        
        self.alphaValue = active ? 1.0 : 0.7
        
        initializeMacros()
        
        self.setOngoingMessage()
    }
    
    func setOngoingMessage() {
        if let text = ChatTrackingHandler.shared.getOngoingMessageFor(chatId: chat?.id, threadUUID: threadUUID) {
            if text.isEmpty {
                return
            }
            
            messageTextView.string = text
            
            self.textDidChange(Notification(name: NSControl.textDidChangeNotification))
        }
    }
    
    func isPaidTextMessage() -> Bool {
        let price = Int(priceTextField.stringValue) ?? 0
        let text = messageTextView.string.trim()
        return price > 0 && !text.isEmpty
    }
    
    func toggleRecordingViews(show: Bool) {
        intermitentAlphaView.toggleAnimation(animate: show)
        
        recordingContainer.isHidden = !show
    }
    
    func toggleRecordButton(enable: Bool) {
        micButton.isEnabled = enable
        micButton.alphaValue = enable ? 1.0 : 0.7
        micButton.cursor = enable ? .pointingHand : .arrow
    }
    
    func recordingProgress(minutes: String, seconds: String) {
        recordingTimeLabel.stringValue = "\(minutes):\(seconds)"
    }
    
    @IBAction func attachmentsButtonClicked(_ sender: Any) {
        delegate?.didClickAttachmentsButton()
    }
    
    @IBAction func giphyButtonClicked(_ sender: Any) {
        delegate?.didClickGiphyButton()
    }
    
    @IBAction func emojiButtonClicked(_ sender: Any) {
        NSApp.orderFrontCharacterPalette(textView)
        self.window?.makeFirstResponder(messageTextView)
    }
    
    @IBAction func sendButtonClicked(_ sender: Any) {
        shouldSendMessage()
    }
    
    @IBAction func micButtonClicked(_ sender: Any) {
        recordingTimeLabel.stringValue = "0:00"
        
        delegate?.didClickMicButton()
    }
    
    @IBAction func cancelRecordingButtonClicked(_ sender: Any) {
        delegate?.didClickCancelRecordingButton()
    }
    
    @IBAction func confirmRecordingButtonClicked(_ sender: Any) {
        delegate?.didClickConfirmRecordingButton()
    }
}
