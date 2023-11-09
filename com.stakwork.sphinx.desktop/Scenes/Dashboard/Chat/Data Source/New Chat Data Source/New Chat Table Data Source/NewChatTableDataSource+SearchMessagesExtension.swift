//
//  NewChatTableDataSource+SearchMessagesExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension NewChatTableDataSource {
    func shouldSearchFor(term: String) {
        let searchTerm = term.trim()
        
        if searchTerm.isNotEmpty && searchTerm.count > 2 {
            performSearch(
                term: searchTerm,
                itemsCount: max(500, self.messagesArray.count)
            )
        } else {
            
            if searchTerm.count > 0 {
                messageBubbleHelper.showGenericMessageView(text: "Search term must be longer than 3 characters")
            }
            
            resetResults()
        }
    }
    
    func performSearch(
        term: String,
        itemsCount: Int
    ) {
        guard let chat = chat else {
            return
        }
        
        let isNewSearch = searchingTerm != term
        let isNewPage = itemsCount > self.messagesArray.count
        
        searchingTerm = term
        
        if isNewPage {
            ///Start listening with this limit to prevent scroll jump on search cancel
            ///If listening was set with lower count, then on cancel could jump since less items are available
            self.configureResultsController(items: itemsCount)
        }
        
        if isNewPage || isNewSearch {
            ///Process messages if loading more items or doing a new search
            self.messagesArray = TransactionMessage.getAllMessagesFor(chat: chat, limit: itemsCount).reversed()
            self.processMessages(messages: self.messagesArray, UIUpdateIndex: self.UIUpdateIndex)
            self.isLastSearchPage = self.messagesArray.count < itemsCount
        }
    }
    
    func resetResults() {
        searchingTerm = nil
        searchMatches = []
        currentSearchMatchIndex = 0
        
        delegate?.didFinishSearchingWith(
            matchesCount: 0,
            index: currentSearchMatchIndex
        )
        
        reloadAllVisibleRows()
    }
    
    func shouldEndSearch() {
        resetResults()
        forceReload()
    }
    
    func processForSearch(
        message: TransactionMessage,
        messageTableCellState: MessageTableCellState,
        index: Int
    ) {
        guard let searchingTerm = searchingTerm else {
            return
        }
        
        if message.isBotHTMLResponse() || message.isPayment() || message.isInvoice() || message.isDeleted() {
            return
        }
        
        if let messageContent = message.bubbleMessageContentString, messageContent.isNotEmpty {
            if messageContent.lowercased().contains(searchingTerm.lowercased()) {
                searchMatches.append(
                    (index, messageTableCellState)
                )
            }
        }
    }
    
    func startSearchProcess() {
        searchMatches = []
    }
    
    func finishSearchProcess() {
        guard let _ = searchingTerm else {
            return
        }
        
        if searchMatches.isEmpty {
            loadMoreItemForSearch()
            return
        }
        
        let isNewSearch = currentSearchMatchIndex == 0
        let oldSearchIndex = currentSearchMatchIndex

        searchMatches = searchMatches.reversed()

        ///should scroll to first results after current scroll position
        if isNewSearch {
            currentSearchMatchIndex = searchMatches.firstIndex(
                where: {
                    $0.0 <= (collectionView.indexPathsForVisibleItems().sorted(by: { return $0.item > $1.item }).first?.item ?? 0)
                }
            ) ?? 0
        }
        
        let isAtSameIndex = oldSearchIndex == currentSearchMatchIndex

        ///Show search results
        DispatchQueue.main.async {
            self.delegate?.didFinishSearchingWith(
                matchesCount: self.searchMatches.count,
                index: self.currentSearchMatchIndex
            )
            
            self.reloadAllVisibleRows() {
                self.scrollToSearchAt(
                    index: self.currentSearchMatchIndex,
                    shouldActuallyScroll: isNewSearch || !isAtSameIndex
                )
            }
        }
    }
    
    func scrollToSearchAt(
        index: Int,
        animated: Bool = false,
        shouldActuallyScroll: Bool = true
    ) {
        if searchMatches.count > index && index >= 0 {
            let searchMatchIndex = searchMatches[index].0
            
            ///It won't scroll if it's loading more items in the past
            if shouldActuallyScroll {
                collectionView.scrollToIndex(
                    targetIndex: searchMatchIndex,
                    animated: animated,
                    position: NSCollectionView.ScrollPosition.top
                )
            }

            if index + 1 == searchMatches.count {
                loadMoreItemForSearch()
            }
        }
    }
    
    func loadMoreItemForSearch() {
        if isLastSearchPage {
            delegate?.shouldToggleSearchLoadingWheel(active: false)
            return
        }

        delegate?.shouldToggleSearchLoadingWheel(active: true)

        DelayPerformedHelper.performAfterDelay(seconds: 0.2, completion: {
            self.performSearch(
                term: self.searchingTerm ?? "",
                itemsCount: self.messagesArray.count + 500
            )
        })
    }
    
    func reloadAllVisibleRows(
        animated: Bool = false,
        completion: (() -> ())? = nil
    ) {
        let tableCellStates = getTableCellStatesForVisibleRows()

        var snapshot = self.dataSource.snapshot()
        snapshot.reloadItems(tableCellStates)
        self.dataSource.apply(snapshot, animatingDifferences: animated) {
            completion?()
        }
    }
    
    func shouldNavigateOnSearchResultsWith(
        button: ChatSearchResultsBar.NavigateArrowButton
    ) {
        switch(button) {
        case ChatSearchResultsBar.NavigateArrowButton.Up:
            currentSearchMatchIndex += 1
            break
        case ChatSearchResultsBar.NavigateArrowButton.Down:
            currentSearchMatchIndex -= 1
            break
        }
        
        scrollToSearchAt(
            index: currentSearchMatchIndex
        )
    }
}
