//
//  NewChatTableDataSource+PreloaderExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension NewChatTableDataSource {
    func preloadDataForItems() {
        for index in stride(from: messageTableCellStateArray.count - 1, through: 0, by: -1) {
            let item = messageTableCellStateArray[index]
            
            if let messageId = item.message?.id {
                DispatchQueue.global(qos: .userInteractive).async {
                    self.preloadDataFor(
                        rowIndex: index,
                        messageId: messageId
                    )
                }
            }
        }
    }
    
    func preloadDataFor(
        rowIndex: Int,
        messageId: Int
    ) {
        if let tableCellState = getTableCellStateFor(
            messageId: messageId,
            and: rowIndex
        ) {
            var mutableCellState = tableCellState
            
            if let link = mutableCellState.1.webLink?.link {
                let linkData = preloaderHelper.linksData[link]
                
                if linkData == nil {
//                    loadLinkDataFor(
//                        messageId: messageId,
//                        and: rowIndex
//                    )
                }
            }
        }
    }
    
    func restorePreloadedMessages() {
        guard let chat = chat else {
            return
        }
        
        if let messagesStateArray = preloaderHelper.getMessageStateArray(for: chat.id) {
            messageTableCellStateArray = messagesStateArray
            updateSnapshot()
        }
    }
    
    func saveMessagesToPreloader() {
        let firstVisibleItem = collectionView.indexPathsForVisibleItems().sorted().first?.item ?? 0
        
        guard let chat = chat, collectionView.numberOfSections > 0 && firstVisibleItem > 0 else {
            return
        }
        
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        
        preloaderHelper.add(
            messageStateArray: messageTableCellStateArray.endSubarray(size: (numberOfItems - firstVisibleItem) + 10),
            for: chat.id
        )
    }
    
    func saveSnapshotCurrentState() {
//        guard let chat = chat else {
//            return
//        }
//
//        if let firstVisibleRow = collectionView.indexPathsForVisibleItems().sorted().first {
//
//            let cellRectInTable = collectionView.rectForRow(at: firstVisibleRow)
//            let cellOffset = tableView.convert(cellRectInTable.origin, to: bottomView)
//
//            preloaderHelper.save(
//                bottomFirstVisibleRow: firstVisibleRow.row,
//                bottomFirstVisibleRowOffset: cellOffset.y,
//                bottomFirstVisibleRowUniqueID: dataSource.snapshot().itemIdentifiers.first?.getUniqueIdentifier(),
//                numberOfItems: preloaderHelper.getPreloadedMessagesCount(for: chat.id),
//                for: chat.id
//            )
//        }
//
        saveMessagesToPreloader()
        saveDistanceFromBottom()
    }
    
    func restoreScrollLastPosition() {
        if let distanceFromBottom = distanceFromBottom {
            let collectionViewContentSize = collectionView.collectionViewLayout?.collectionViewContentSize.height ?? 0
            let offset = (collectionViewContentSize - collectionViewScroll.frame.height - distanceFromBottom) - collectionViewScroll.contentInsets.top
            collectionViewScroll.documentYOffset = offset
        } else {
            let collectionViewContentSize = collectionView.collectionViewLayout?.collectionViewContentSize.height ?? 0
            scrollViewDesiredOffset = collectionViewContentSize - collectionViewScroll.frame.height + collectionViewScroll.contentInsets.top
            collectionViewScroll.documentYOffset = scrollViewDesiredOffset ?? 0
        }
        
//        guard let chat = chat else {
//            return
//        }
//        
//        if let scrollState = preloaderHelper.getScrollState(
//            for: chat.id,
//            with: dataSource.snapshot().itemIdentifiers
//        ) {
//            let row = scrollState.bottomFirstVisibleRow
//            let offset = scrollState.bottomFirstVisibleRowOffset
//            
//            if scrollState.shouldAdjustScroll && !loadingMoreItems {
//                
//                if tableView.numberOfRows(inSection: 0) > row {
//                    
//                    tableView.scrollToRow(
//                        at: IndexPath(row: row, section: 0),
//                        at: .top,
//                        animated: false
//                    )
//                    
//                    tableView.contentOffset.y = tableView.contentOffset.y + (offset + tableView.contentInset.top)
//                }
//            }
//            
//            if scrollState.shouldPreventSetMessagesAsSeen {
//                return
//            }
//        }
//        
//        if tableView.contentOffset.y <= Constants.kChatTableContentInset {
//            delegate?.didScrollToBottom()
//        }
    }
    
    func getCollectionViewContentSize() -> CGFloat {
        guard let collectionViewLayout = collectionView.collectionViewLayout else {
            return CGFloat.zero
        }

        return collectionViewLayout.collectionViewContentSize.height
    }
    
    func saveDistanceFromBottom() {
        guard let enclosingScrollView = collectionView.enclosingScrollView else { return }
        
        if collectionView.alphaValue == 0 { return }
                
        let contentHeight = getCollectionViewContentSize()
        
        if contentHeight == 0 { return }
        
        let scrollViewHeight = enclosingScrollView.bounds.height
        let contentOffsetY = enclosingScrollView.contentView.bounds.origin.y
        let topInset = enclosingScrollView.contentInsets.top
        
        self.distanceFromBottom = contentHeight - (contentOffsetY + scrollViewHeight) - topInset
    }

}
