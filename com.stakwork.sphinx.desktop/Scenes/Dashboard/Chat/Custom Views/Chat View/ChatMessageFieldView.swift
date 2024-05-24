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
    @IBOutlet weak var priceTag: CustomButton!
    
    
    @IBOutlet weak var recordingContainer: NSBox!
    @IBOutlet weak var intermitentAlphaView: IntermitentAlphaAnimatedView!
    @IBOutlet weak var recordingTimeLabel: NSTextField!
    
    @IBOutlet weak var messageContainerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var addDocumentCustomView: NSView!
    @IBOutlet weak var stackView: NSBox!
    @IBOutlet weak var priceCancelButton: NSBox!
    @IBOutlet weak var priceCancelButtonWidthConstraint: NSLayoutConstraint!
    
    let kTextViewVerticalMargins: CGFloat = 41
    let kCharacterLimit = 1000
    let kTextViewLineHeight: CGFloat = 19
    let kMinimumPriceFieldWidth: CGFloat = 90
    let kPriceClearButtonWidth: CGFloat = 20
    let kPriceFieldPadding: CGFloat = 10
    
    let kFieldPlaceHolder = "message.placeholder".localized
    
    var macros : [MentionOrMacroItem] = []
    
    var chat: Chat? = nil
    var contact: UserContact? = nil
    var threadUUID: String? = nil
    
    var isThreadOpen: Bool = false
    
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
        isThreadOpen = true
        priceContainer.isHidden = true
    }
    
    func setupView() {
        setupButtonsCursor()
        setupMessageField()
        setupPriceField()
        setupAttachmentButton()
        setupSendButton()
        setupMicButton()
        setupIntermitentAlphaView()
        showPriceClearButton()
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
        stackView.wantsLayer = true
        priceContainer.wantsLayer = true
        priceTextField.delegate = self
        
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
        
        messageTextView.textColor = NSColor.Sphinx.PrimaryText
        
        messageTextView.delegate = self
        messageTextView.fieldDelegate = self
        
        if let layer = stackView.layer {
            layer.backgroundColor = NSColor.Sphinx.ReceivedMsgBG.cgColor
            layer.cornerRadius = stackView.frame.height / 2
            layer.masksToBounds = true
        }
        
        if let layer = priceContainer.layer  {
            layer.masksToBounds = true
            layer.cornerRadius = priceContainer.frame.height / 2
            layer.backgroundColor = NSColor.Sphinx.PriceTagBG.cgColor
            layer.borderWidth = 1
            layer.borderColor = NSColor.clear.cgColor
        }
        
        updateColor()
    }
    
    func setupPriceField() {
        priceContainer.wantsLayer = true
        priceContainer.layer?.cornerRadius = priceContainer.frame.height / 2
        priceTextField.color = priceTextField.stringValue.isEmpty ? NSColor.Sphinx.SecondaryText : NSColor.Sphinx.PrimaryText
        priceTextField.formatter = IntegerValueFormatter()
        priceTextField.delegate = self
        priceTextField.isEditable = false
    }
    
    func setupAttachmentButton() {
        attachmentsButton.wantsLayer = true
        attachmentsButton.layer?.cornerRadius = attachmentsButton.frame.height / 2
        attachmentsButton.isEnabled = false
    }
    
    func setupMicButton() {
        micButton.wantsLayer = true
        micButton.layer?.cornerRadius = sendButton.frame.height / 2
        micButton.layer?.backgroundColor = NSColor.Sphinx.PrimaryBlue.cgColor
        micButton.isEnabled = true
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
        let newFieldHeight = min(updatedHeight, kTextViewLineHeight * 11) + 12
        
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
        priceTextField.isEditable = active
        updatePriceTagField()
        
        alphaValue = active ? 1.0 : 0.7
        
        initializeMacros()
        setOngoingMessage()
    }
    
    func updatePriceTagField() {
        priceTextField.isHidden = isThreadOpen
        
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        
        priceTextField.placeholderAttributedString = NSAttributedString(
            string: isThread ? "" : "Add Price",
            attributes: [
                NSAttributedString.Key.font: NSFont(name: "Roboto-Regular", size: 14.0)!,
                NSAttributedString.Key.foregroundColor: NSColor.Sphinx.SecondaryText,
                NSAttributedString.Key.paragraphStyle: style
            ]
        )
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
    
    @IBAction func priceCancelButtonClicked(_ sender: Any) {
        priceTextField.stringValue = ""
        updatePriceFieldWidth()
    }
    
    func showPriceClearButton() {
        priceCancelButton.isHidden = priceTextField.stringValue.isEmpty
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
    
    @IBAction func tagButtonClicked(_ sender: Any) {
        priceTextField.isHidden = false
        updatePriceFieldWidth()
        self.window?.makeFirstResponder(priceTextField)
    }
}
