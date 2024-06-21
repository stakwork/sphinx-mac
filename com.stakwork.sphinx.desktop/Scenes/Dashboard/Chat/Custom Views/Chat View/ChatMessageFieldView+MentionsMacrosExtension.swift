//
//  ChatMessageFieldView+MentionsMacrosExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension ChatMessageFieldView {
    func populateMentionAutocomplete(
        autocompleteText: String
    ) {
        let text = messageTextView.string
        
        if let typedMentionText = self.getAtMention(
            text: text,
            cursorPosition: messageTextView.cursorPosition
        ) {
            let initialPosition = messageTextView.cursorPosition
            let rangeLocation = messageTextView.rangeLocation
            
            let startIndex = text.index(text.startIndex, offsetBy: (initialPosition ?? 0) - typedMentionText.count)
            let endIndex = text.index(text.startIndex, offsetBy: (initialPosition ?? 0))
                                    
            // insertText triggers the textDidChange delegate method
            // whereas setting the string directly does not, which is
            // needed when autocompleting based on enter/return key press
            let range = NSRange((startIndex..<endIndex), in: messageTextView.string)
            messageTextView.insertText("@\(autocompleteText) ", replacementRange: range)
            
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.01,
                execute: {
                    self.messageTextView.string = self.messageTextView.string.replacingOccurrences(of: "\t", with: "")
                    
                    let position = (rangeLocation ?? 0) + ("@\(autocompleteText) ".count - typedMentionText.count)
                    self.messageTextView.setSelectedRange(NSRange(location: position, length: 0))
                    self.messageTextView.window?.makeFirstResponder(self.messageTextView)
                }
            )
        }
    }
    
    func processMention(
        text: String,
        cursorPosition: Int
    ) {
        if let mention = getAtMention(
            text: text,
            cursorPosition: cursorPosition
        ) {
            let mentionValue = String(mention).replacingOccurrences(of: "@", with: "").lowercased()
            self.didDetectPossibleMentions(mentionText: mentionValue, cursorPoint: cursorPosition)
        } else {
            self.didDetectPossibleMentions(mentionText: "", cursorPoint: cursorPosition)
        }
    }
    
    func getAtMention(
        text: String,
        cursorPosition: Int?) -> String? {
            
        let relevantText = text[0..<(cursorPosition ?? text.count)]
            
        if let lastLetter = relevantText.last, lastLetter == " " || lastLetter == "\n" {
            return nil
        }
            
        if
            let lastLine = relevantText.split(separator: "\n").last,
            let lastWord = lastLine.split(separator: " ").last,
            let firstLetter = lastWord.first, firstLetter == "@" {
            
            return String(lastWord)
        }
        return nil
    }
    
    func getMentionsFrom(
        mentionText: String
    ) -> [(String, String)] {
        var possibleMentions: [(String, String)] = []
        
        if mentionText.count > 0 {
            for alias in self.chat?.aliasesAndPics ?? [] {
                if (mentionText.count > alias.0.count) {
                    continue
                }
                let substring = alias.0.substring(range: NSRange(location: 0, length: mentionText.count))
                if (substring.lowercased() == mentionText && mentionText.isEmpty == false) {
                    possibleMentions.append(alias)
                }
            }
        }
        
        return possibleMentions
    }
    
    func didDetectPossibleMentions(
        mentionText: String, 
        cursorPoint: Int
    ) {
        let possibleMentions = self.getMentionsFrom(mentionText: mentionText)
        let suggestionObjects = possibleMentions.compactMap({
            let result = MentionOrMacroItem(
                type: .mention,
                displayText: $0.0,
                imageLink: $0.1,
                action: nil
            )
            return result
        })
        
        delegate?.shouldUpdateMentionSuggestionsWith(
            suggestionObjects,
            text: mentionText,
            cursorPosition: cursorPoint
        )
    }
}

extension ChatMessageFieldView {
    @discardableResult func didTapTab() -> Bool {
        if let selectedMention = delegate?.shouldGetSelectedMention() {
            populateMentionAutocomplete(
                autocompleteText: selectedMention
            )
            return true
        } else if let action = delegate?.shouldGetSelectedMacroAction() {
            processGeneralPurposeMacro(
                action: action
            )
            return true
        }
        
        return false
    }
    
    func didTapEscape() {
        delegate?.didTapEscape()
    }
    
    func didTapUpArrow() -> Bool {
        return delegate?.didTapUpArrow() ?? false
    }
    
    func didTapDownArrow() -> Bool {
        return delegate?.didTapDownArrow() ?? false
    }
}

extension ChatMessageFieldView {
    func initializeMacros() {
        guard let chat = chat else {
            return
        }
        
        self.macros = [
            MentionOrMacroItem(
                type: .macro,
                displayText: "send.giphy".localized,
                image: NSImage(named: "giphyIcon"),
                action: {
                    self.delegate?.didClickGiphyButton()
                }
            ),
            MentionOrMacroItem(
                type: .macro,
                displayText: "start.audio.call".localized,
                icon: "call",
                action: {
                    self.delegate?.shouldCreateCall(mode: .Audio)
                }
            ),
            MentionOrMacroItem(
                type: .macro,
                displayText: "start.video.call".localized,
                icon: "video_call",
                action: {
                    self.delegate?.shouldCreateCall(mode: .All)
                }
            ),
            MentionOrMacroItem(
                type: .macro,
                displayText: "send.emoji".localized,
                icon: "mood",
                action: {
                    self.emojiButtonClicked(self.emojiButton as Any)
                }
            ),
            MentionOrMacroItem(
                type: .macro,
                displayText: "record.voice".localized,
                icon: "mic",
                action: {
                    self.micButtonClicked(self)
                }
            )
        ]
        
        if !chat.isPublicGroup() {
            macros.append(
                contentsOf: [
                    MentionOrMacroItem(
                        type: .macro,
                        displayText: "send.payment".localized,
                        image: NSImage(named: "bottomBar4"),
                        action: {
                            self.delegate?.didSelectSendPaymentMacro()
                        }
                    ),
                    MentionOrMacroItem(
                        type: .macro,
                        displayText: "request.payment".localized,
                        image: NSImage(named: "bottomBar1"),
                        action: {
                            self.delegate?.didSelectReceivePaymentMacro()
                        }
                    )
                ]
            )
        }
    }
    
    func processGeneralPurposeMacro(
        action: @escaping () -> ()
    ) {
        action()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
            self.messageTextView.string = ""
            self.textDidChange(Notification(name: Notification.Name(rawValue: "")))
        })
    }
    
    func processMacro(
        text: String,
        cursorPosition: Int
    ) {
        var localMacros : [MentionOrMacroItem] = []
        
        if let macro = getMacro(
            text: text,
            cursorPosition: cursorPosition
        ) {
            let macrosText = String(macro).replacingOccurrences(of: "/", with: "").lowercased()
            let possibleMacros = self.macros.compactMap({ $0.displayText }).filter({
                let actionText = $0.lowercased()
                return actionText.contains(macrosText.lowercased()) || macrosText == ""
            }).sorted()
            
            localMacros = macros.filter({macroObject in
                return possibleMacros.contains(macroObject.displayText)
            })
            
            delegate?.shouldUpdateMentionSuggestionsWith(
                localMacros.reversed(),
                text: "/",
                cursorPosition: cursorPosition
            )
        }
    }
    
    func getMacro(
        text: String,
        cursorPosition: Int?
    ) -> String? {
        let relevantText = text[0..<(cursorPosition ?? text.count)]
        if let firstLetter = relevantText.first, firstLetter == "/" {
            return relevantText
        }

        return nil
    }
}
