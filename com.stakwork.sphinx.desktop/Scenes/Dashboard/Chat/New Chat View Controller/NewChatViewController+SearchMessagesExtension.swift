//
//  NewChatViewController+SearchMessagesExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/10/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension NewChatViewController {
    func toggleSearchMode(active: Bool) {
        viewMode = active ? ViewMode.Search : ViewMode.Standard
        
        chatBottomView.configureSearchWith(
            active: active,
            loading: false,
            matchesCount: 0
        )
        
        chatTopView.configureSearchMode(
            active: active
        )
    }
}

extension NewChatViewController : ChatSearchTextFieldViewDelegate {
    func shouldSearchFor(term: String) {
        chatBottomView.configureSearchWith(
            active: true,
            loading: true
        )
        
        chatTableDataSource?.shouldSearchFor(term: term)
    }
    
    func didTapSearchCancelButton() {
        chatBottomView.shouldToggleSearchLoadingWheel(
            active: true,
            showLabel: false
        )
        
        DispatchQueue.main.async {
            self.chatTableDataSource?.shouldEndSearch()
            self.toggleSearchMode(active: false)
            self.setMessageFieldActive()
        }
    }
}

extension NewChatViewController : ChatSearchResultsBarDelegate {
    func didTapNavigateArrowButton(
        button: ChatSearchResultsBar.NavigateArrowButton
    ) {
        chatTableDataSource?.shouldNavigateOnSearchResultsWith(button: button)
    }
}

extension NewChatViewController {
    func didFinishSearchingWith(
        matchesCount: Int,
        index: Int
    ) {
        chatBottomView.configureSearchWith(
            active: true,
            loading: false,
            matchesCount: matchesCount,
            matchIndex: index
        )
    }
    
    func shouldToggleSearchLoadingWheel(active: Bool) {
        chatBottomView.shouldToggleSearchLoadingWheel(active: active)
    }
}
