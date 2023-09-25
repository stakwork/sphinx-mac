//
//  ChatBottomView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 07/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol ChatBottomViewDelegate : AnyObject {
    ///IBActions
    func didClickAttachmentsButton()
    func didClickGiphyButton()
    func didClickMicButton()
    func didClickConfirmRecordingButton()
    func didClickCancelRecordingButton()
    
    ///Mentions and Macros
    func shouldUpdateMentionSuggestionsWith(_ object: [MentionOrMacroItem])
    func shouldGetSelectedMention() -> String?
    func shouldGetSelectedMacroAction() -> (() -> ())?
    func didTapUpArrow() -> Bool
    func didTapDownArrow() -> Bool
    func didSelectSendPaymentMacro()
    func didSelectReceivePaymentMacro()
    
    
    ///Sending message
    func shouldSendMessage(text: String, price: Int, completion: @escaping (Bool) -> ())
}

class ChatBottomView: NSView, LoadableNib {

    @IBOutlet var contentView: NSView!

    @IBOutlet weak var messageReplyView: NewMessageReplyView!
    @IBOutlet weak var giphySearchView: GiphySearchView!
    @IBOutlet weak var messageFieldView: ChatMessageFieldView!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        
        setup()
    }
    
    func setup() {
        self.addShadow(
            location: VerticalLocation.top,
            color: NSColor.black,
            opacity: 0.3,
            radius: 5.0
        )
    }
    
    func updateFieldStateFrom(
        _ chat: Chat?,
        and contact: UserContact?,
        with delegate: ChatBottomViewDelegate?
    ) {
        self.isHidden = (chat == nil && contact == nil)
        
        messageFieldView.updateFieldStateFrom(
            chat,
            and: contact,
            with: delegate
        )
    }
    
    func updateBottomBarHeight() {
        let _ = messageFieldView.updateBottomBarHeight()
    }
    
    func setMessageFieldActive() {
        messageFieldView.setMessageFieldActive()
    }
    
    func loadGiphySearchWith(
        delegate: GiphySearchViewDelegate
    ) {
        giphySearchView.loadGiphySearch(
            delegate: delegate
        )
    }
    
    func populateMentionAutocomplete(
        autocompleteText: String
    ) {
        messageFieldView.populateMentionAutocomplete(
            autocompleteText: autocompleteText
        )
    }
    
    func processGeneralPurposeMacro(
        action: @escaping () -> ()
    ) {
        messageFieldView.processGeneralPurposeMacro(
            action: action
        )
    }
    
    func isPaidTextMessage() -> Bool {
        return messageFieldView.isPaidTextMessage()
    }
    
    func configureReplyViewFor(
        message: TransactionMessage? = nil,
        podcastComment: PodcastComment? = nil,
        owner: UserContact,
        withDelegate delegate: NewMessageReplyViewDelegate
    ) {
        if let message = message {
            messageReplyView.configureForKeyboard(
                with: message,
                owner: owner,
                and: delegate
            )
        } else if let podcastComment = podcastComment {
            messageReplyView.configureForKeyboard(
                with: podcastComment,
                and: delegate
            )
        }
    }
    
    func resetReplyView() {
        messageReplyView.resetAndHide()
    }
    
    func clearMessage() {
        messageFieldView.clearMessage()
    }
    
    func toggleRecordingViews(show: Bool) {
        messageFieldView.toggleRecordingViews(show: show)
    }
    
    func toggleRecordButton(enable: Bool) {
        messageFieldView.toggleRecordButton(enable: enable)
    }
    
    func recordingProgress(minutes: String, seconds: String) {
        messageFieldView.recordingProgress(minutes: minutes, seconds: seconds)
    }
}
