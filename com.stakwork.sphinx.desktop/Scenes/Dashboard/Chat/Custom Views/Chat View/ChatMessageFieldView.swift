//
//  ChatMessageFieldView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 07/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ChatMessageFieldView: NSView, LoadableNib {

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
    
    @IBOutlet weak var messageContainerHeightConstraint: NSLayoutConstraint!
    
    let kTextViewVerticalMargins: CGFloat = 41
    let kCharacterLimit = 1000
    let kTextViewLineHeight: CGFloat = 19
    let kMinimumPriceFieldWidth: CGFloat = 50
    let kPriceFieldPadding: CGFloat = 10
    
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
    
    func setupView() {
        setupMessageField()
        setupPriceField()
        setupAttachmentButton()
        setupSendButton()
        
        self.addShadow(
            location: VerticalLocation.top,
            color: NSColor.black,
            opacity: 0.3,
            radius: 5.0
        )
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
        sendButton.cursor = .pointingHand
    }
    
    func updateBottomBarHeight() -> Bool {
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
}

extension ChatMessageFieldView : NSTextViewDelegate, MessageFieldDelegate {
    func textView(
        _ textView: NSTextView,
        shouldChangeTextIn affectedCharRange: NSRange,
        replacementString: String?
    ) -> Bool {
        if let replacementString = replacementString, replacementString == "\n" {
//            if sendButton.isEnabled {
//                shouldSendMessage()
//            }
            return false
        }
        
        let currentString = textView.string as NSString
        
        let currentChangedString = currentString.replacingCharacters(
            in: affectedCharRange,
            with: replacementString ?? ""
        )
        
        return (currentChangedString.count <= kCharacterLimit)
    }
    
    func textDidChange(_ notification: Notification) {
//        chat?.setOngoingMessage(text: messageTextView.string)
//
//        processMention(text: messageTextView.string, cursorPosition: messageTextView.cursorPosition ?? 0)
//        processMacro(text: messageTextView.string, cursorPosition: messageTextView.cursorPosition)
        
        let didUpdateHeight = updateBottomBarHeight()
        if !didUpdateHeight {
            return
        }
        
//        if chatCollectionView.shouldScrollToBottom() {
//            chatCollectionView.scrollToBottom(animated: false)
//        }
    }
    
    func didTapTab(){
//        if let selectedMention = chatMentionAutocompleteDataSource?.getSelectedValue() {
//            populateMentionAutocomplete(
//                autocompleteText: selectedMention
//            )
//        } else if let datasource = chatMentionAutocompleteDataSource, let action = datasource.getSelectedAction() {
//            self.processGeneralPurposeMacro(
//                action: action
//            )
//        }
    }
    
    func didDetectPossibleMentions(mentionText:String) {}
    
    func didTapUpArrow() -> Bool {
        return false
    }
    
    func didTapDownArrow() -> Bool {
        return false
    }
    
    func didDetectImagePaste(pasteBoard: NSPasteboard) -> Bool {
        return false
    }
}

extension ChatMessageFieldView : NSTextFieldDelegate {
    func controlTextDidChange(
        _ obj: Notification
    ) {
        updatePriceFieldWidth()
    }
    
    func updatePriceFieldWidth() {
        let currentString = (priceTextField?.stringValue ?? "")
        
        let width = NSTextField().getStringSize(
            text: currentString,
            font: NSFont.systemFont(ofSize: 15, weight: .semibold)
        ).width
        
        priceTextFieldWidth.constant = (
            width < (kMinimumPriceFieldWidth - kPriceFieldPadding)
        ) ? kMinimumPriceFieldWidth : width + kPriceFieldPadding
        
        priceTextField.superview?.layoutSubtreeIfNeeded()
    }
    
    func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
//            if sendButton.isEnabled {
//                shouldSendMessage()
//            }
            return true
        }
        return false
    }
}
