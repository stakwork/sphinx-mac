//
//  ChatMessageFieldView+FieldsExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

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
