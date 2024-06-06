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
    func shouldUpdateMentionSuggestionsWith(
        _ object: [MentionOrMacroItem],
        text: String,
        cursorPosition: Int
    )
    func shouldGetSelectedMention() -> String?
    func shouldGetSelectedMacroAction() -> (() -> ())?
    func didTapUpArrow() -> Bool
    func didTapDownArrow() -> Bool
    func didTapEscape()
    func didSelectSendPaymentMacro()
    func didSelectReceivePaymentMacro()
    func shouldCreateCall(mode: VideoCallHelper.CallMode)
    
    ///UI
    func isChatAtBottom() -> Bool
    func shouldScrollToBottom()
    
    ///Sending message
    func shouldSendMessage(text: String, price: Int, completion: @escaping (Bool) -> ())
    func shouldMainChatOngoingMessage()
}

class ChatBottomView: NSView, LoadableNib {
    
    weak var searchDelegate: ChatSearchResultsBarDelegate?

    @IBOutlet var contentView: NSView!

    @IBOutlet weak var messageReplyView: KeyboardReplyView!
    @IBOutlet weak var giphySearchView: GiphySearchView!
    @IBOutlet weak var messageFieldView: ChatMessageFieldView!
    @IBOutlet weak var chatSearchView: ChatSearchResultsBar!
    
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
        if NSAppearance.current.name == .darkAqua {
            self.removeShadow()
        } else {
            self.addShadow(
                location: VerticalLocation.top,
                color: NSColor.black,
                opacity: 0.1,
                radius: 5.0
            )
        }
    }
    
    func updateFieldStateFrom(
        _ chat: Chat?,
        contact: UserContact?,
        threadUUID: String?,
        with delegate: ChatBottomViewDelegate?,
        and searchDelegate: ChatSearchResultsBarDelegate? = nil
    ) {
        self.searchDelegate = searchDelegate
        
        self.isHidden = (chat == nil && contact == nil)
        
        messageFieldView.updateFieldStateFrom(
            chat,
            contact: contact,
            threadUUID: threadUUID,
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

//Search Mode
extension ChatBottomView {
    func configureSearchWith(
        active: Bool,
        loading: Bool,
        matchesCount: Int? = nil,
        matchIndex: Int = 0
    ) {
        messageReplyView.isHidden = true
        giphySearchView.isHidden = true
        messageFieldView.isHidden = active
        
        chatSearchView.isHidden = !active
        
        chatSearchView.configureWith(
            matchesCount: matchesCount,
            matchIndex: matchIndex,
            loading: loading,
            delegate: self
        )
    }
    
    func shouldToggleSearchLoadingWheel(
        active: Bool,
        showLabel: Bool = true
    ) {
        chatSearchView.toggleLoadingWheel(
            active: active,
            showLabel: showLabel
        )
    }
}

extension ChatBottomView : ChatSearchResultsBarDelegate {
    func didTapNavigateArrowButton(button: ChatSearchResultsBar.NavigateArrowButton) {
        searchDelegate?.didTapNavigateArrowButton(button: button)
    }
}
