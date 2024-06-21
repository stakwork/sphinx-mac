//
//  NewChatViewController+MentionsExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 17/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension NewChatViewController {
    func processChatAliases() {
        chat?.processAliases()
    }
    
    func configureMentionAutocompleteTableView() {
        if chatMentionAutocompleteDataSource != nil {
            return
        }
        
        mentionsCollectionView.isHidden = false
        
        chatMentionAutocompleteDataSource = ChatMentionAutocompleteDataSource(
            tableView: mentionsCollectionView,
            scrollView: mentionsScrollView,
            viewWidth: self.chatCollectionView.frame.width,
            delegate: self
        )
    }
}

extension NewChatViewController : ChatMentionAutocompleteDelegate {
    func processAutocomplete(
        text: String
    ) {
        chatBottomView.populateMentionAutocomplete(autocompleteText: text)
        chatMentionAutocompleteDataSource?.updateMentionSuggestions(suggestions: [])
    }
    
    func processGeneralPurposeMacro(
        action: @escaping ()->()
    ) {
        chatMentionAutocompleteDataSource?.setViewWidth(viewWidth: self.chatCollectionView.frame.width)
        
        chatBottomView.processGeneralPurposeMacro(action: action)
        chatMentionAutocompleteDataSource?.updateMentionSuggestions(suggestions: [])
    }
    
    func shouldUpdateTableHeightTo(value: CGFloat) {
        mentionsScrollViewHeightConstraint.constant = value
        mentionsScrollView.layoutSubtreeIfNeeded()
    }
}
