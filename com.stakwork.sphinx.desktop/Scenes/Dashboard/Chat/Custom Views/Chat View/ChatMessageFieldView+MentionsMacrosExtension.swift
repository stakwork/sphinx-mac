//
//  ChatMessageFieldView+MentionsMacrosExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension ChatMessageFieldView {
    func processMention(
        text: String,
        cursorPosition: Int
    ) {
        if let mention = getAtMention(text: text,cursorPosition: cursorPosition) {
            let mentionValue = String(mention).replacingOccurrences(of: "@", with: "").lowercased()
//            self.didDetectPossibleMentions(mentionText: mentionValue)
        } else {
//            self.didDetectPossibleMentions(mentionText: "")
        }
    }
    
    func getAtMention(text:String,cursorPosition:Int?)->String?{
        let relevantText = text[0..<(cursorPosition ?? text.count)]
        if let lastLetter = relevantText.last, lastLetter == " " {
            return nil
        }
        if let lastLine = relevantText.split(separator: "\n").last,
            let lastWord = lastLine.split(separator: " ").last,
           let firstLetter = lastWord.first,
           firstLetter == "@"{
            return String(lastWord)
        }
        return nil
    }
}

extension ChatMessageFieldView {
    func initializeMacros() {
        self.macros = [
            MentionOrMacroItem(
                type: .macro,
                displayText: "send.giphy".localized,
                image: NSImage(named: "giphyIcon"),
                action: {
//                    self.giphyButtonClicked(self)
                }
            ),
            MentionOrMacroItem(
                type: .macro,
                displayText: "start.audio.call".localized,
                icon: "call",
                action: {
//                    self.shouldCreateCall(mode: .Audio)
                }
            ),
            MentionOrMacroItem(
                type: .macro,
                displayText: "start.video.call".localized,
                icon: "video_call",
                action: {
//                    self.shouldCreateCall(mode: .All)
                }
            ),
            MentionOrMacroItem(
                type: .macro,
                displayText: "send.emoji".localized,
                icon: "mood",
                action: {
//                    self.emojiButtonClicked(self)
                }
            ),
            MentionOrMacroItem(
                type: .macro,
                displayText: "record.voice".localized,
                icon: "mic",
                action: {
//                    self.micButtonClicked(self)
                }
            )
        ]
        
        let isTribe = chat?.isPublicGroup() == false
        
        if !isTribe {
            macros.append(
                contentsOf: [
                    MentionOrMacroItem(
                        type: .macro,
                        displayText: "send.payment".localized,
                        image: NSImage(named: "bottomBar4"),
                        action: {
//                            self.macroDoPayment(buttonTag: ChildVCContainer.ChildVCOptionsMenuButton.Send)
                        }
                    ),
                    MentionOrMacroItem(
                        type: .macro,
                        displayText: "request.payment".localized,
                        image: NSImage(named: "bottomBar1"),
                        action: {
//                            self.macroDoPayment(buttonTag: ChildVCContainer.ChildVCOptionsMenuButton.Request)
                        }
                    )
                ]
            )
        }
    }
    
    func processMacro(
        text: String,
        cursorPosition: Int
    ) {
        var localMacros : [MentionOrMacroItem] = []
        
        if let macro = getMacro(
            text: text,
            cursorPosition:cursorPosition
        ) {
            let macrosText = String(macro).replacingOccurrences(of: "/", with: "").lowercased()
            let possibleMacros = self.macros.compactMap({ $0.displayText }).filter({
                let actionText = $0.lowercased()
                return actionText.contains(macrosText.lowercased()) || macrosText == ""
            }).sorted()
            
            localMacros = macros.filter({macroObject in
                return possibleMacros.contains(macroObject.displayText)
            })
        }
        
//        if(chatMentionAutocompleteDataSource?.suggestions.count == 0){
//            chatMentionAutocompleteDataSource?.updateMentionSuggestions(suggestions: localMacros.reversed())
//        }
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
