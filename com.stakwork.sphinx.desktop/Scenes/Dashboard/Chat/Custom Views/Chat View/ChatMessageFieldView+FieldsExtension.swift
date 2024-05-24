//
//  ChatMessageFieldView+FieldsExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension ChatMessageFieldView {
    func setMessageFieldActive() {
        self.window?.makeFirstResponder(messageTextView)
    }
}

extension ChatMessageFieldView : NSTextViewDelegate, MessageFieldDelegate {
    func textView(
        _ textView: NSTextView,
        shouldChangeTextIn affectedCharRange: NSRange,
        replacementString: String?
    ) -> Bool {
        if let replacementString = replacementString, replacementString == "\n" {
            shouldSendMessage()
            return false
        }
        
        let currentString = textView.string as NSString
        
        let currentChangedString = currentString.replacingCharacters(
            in: affectedCharRange,
            with: replacementString ?? ""
        )
        
        return (currentChangedString.count <= kCharacterLimit)
    }
    
    func shouldSendMessage() {
        if sendButton.isEnabled {
            delegate?.shouldSendMessage(
                text: messageTextView.string.trim(),
                price: Int(priceTextField.stringValue) ?? 0,
                completion: { success in
                    if !success {
                        AlertHelper.showAlert(
                            title: "generic.error.title".localized,
                            message: "generic.message.error".localized
                        )
                    }
                }
            )
            
            clearMessage()
        }
    }
    
    func clearMessage() {
        messageTextView.string = ""
        priceTextField.stringValue = ""
        textDidChange(Notification(name: NSControl.textDidChangeNotification))
        
        updateColor()
        delegate?.shouldMainChatOngoingMessage()
    }
    
    func textDidChange(_ notification: Notification) {
        micButton.isHidden = !messageTextView.string.isEmpty
        priceContainer.isHidden = messageTextView.string.isEmpty || isThread
        sendButton.isHidden = messageTextView.string.isEmpty
        priceTextField.stringValue = messageTextView.string.isEmpty ? "" : priceTextField.stringValue
        
        updateColor()
        
        ChatTrackingHandler.shared.saveOngoingMessage(
            with: messageTextView.string,
            chatId: chat?.id,
            threadUUID: threadUUID
        )

        processMention(
            text: messageTextView.string,
            cursorPosition: messageTextView.cursorPosition ?? 0
        )
        
        processMacro(
            text: messageTextView.string,
            cursorPosition: messageTextView.cursorPosition ?? 0
        )
        
        let didUpdateHeight = updateBottomBarHeight()
        if !didUpdateHeight {
            return
        }
        
//        if chatCollectionView.shouldScrollToBottom() {
//            chatCollectionView.scrollToBottom(animated: false)
//        }
    }
    
    func updateColor() {
        let active: Bool = !priceTextField.stringValue.isEmpty
        
        let plusIconColor = active ?
        NSColor.Sphinx.GreenBorder :
        NSColor.Sphinx.SecondaryText
        
        let iconsColor = active ?
        NSColor.Sphinx.GreenBorder :
        NSColor.Sphinx.PlaceholderText
        
        let messageColor = active ?
        NSColor.Sphinx.TextViewGreenColor :
        NSColor.Sphinx.TextViewBGColor
        
        let sendColor = active ? 
        NSColor.Sphinx.GreenBorder.cgColor:
        NSColor.Sphinx.PrimaryBlue.cgColor
        
        if let layer = priceContainer.layer  {
            layer.masksToBounds = true
            layer.cornerRadius = priceContainer.frame.height / 2
            layer.backgroundColor = active ? NSColor.Sphinx.TextViewBGColor.cgColor : NSColor.Sphinx.PriceTagBG.cgColor
            layer.borderWidth = 1
            layer.borderColor = active ? NSColor.Sphinx.GreenBorder.cgColor : NSColor.clear.cgColor
            
        }
        
        updateSendButtonColor(color: sendColor)
        updateMessageBGColor(color: messageColor)
        
        updateIconsColor(
            plusIconColor: plusIconColor,
            iconsColor: iconsColor
        )
    }
    
    func updateIconsColor(
        plusIconColor: NSColor,
        iconsColor: NSColor
    ) {
        emojiButton.contentTintColor = iconsColor
        giphyButton.contentTintColor = iconsColor
        priceTag.contentTintColor = iconsColor
        attachmentsButton.contentTintColor = plusIconColor
    }
    
    func updateSendButtonColor(color: CGColor) {
        sendButton.layer?.backgroundColor = color
    }
    
    func updateMessageBGColor(color: NSColor) {
        stackView.fillColor = color
    }
    
    func didDetectFilePaste(pasteBoard: NSPasteboard) -> Bool {
        let hasFiles = ClipboardHelper().clipboardHasFiles(pasteBoard: pasteBoard)
        
        if hasFiles == true {
            NotificationCenter.default.post(name: .onFilePaste, object: nil)
        }

        return hasFiles
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
            font: NSFont(name: "Roboto-Regular", size: 14.0)!
        ).width
        
        showPriceClearButton()
        updateColor()
        
        var widthConstant: CGFloat = 0
        
        if priceTextField.stringValue.isEmpty {
            widthConstant = kMinimumPriceFieldWidth
        } else {
            if width + kPriceFieldPadding > (kMinimumPriceFieldWidth - kPriceClearButtonWidth) {
                widthConstant = width + kPriceFieldPadding
            } else {
                widthConstant = kMinimumPriceFieldWidth - kPriceClearButtonWidth
            }
        }
        
        priceTextFieldWidth.constant = widthConstant
        
        priceTextField.superview?.layoutSubtreeIfNeeded()
    }
    
    func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            shouldSendMessage()
            return true
        }
        return false
    }
}
