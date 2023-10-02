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
    
    @objc func restorePreloadedMessages() {
        guard let chat = chat else {
            return
        }
        
        if let messagesStateArray = preloaderHelper.getMessageStateArray(for: chat.id) {
            messageTableCellStateArray = messagesStateArray
            updatePreloadedSnapshot()
        }
    }
    
    @objc func saveMessagesToPreloader() {
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
    
    @objc func saveSnapshotCurrentState() {
        saveScrollPosition()
        saveMessagesToPreloader()
    }
    
    @objc func restoreScrollLastPosition() {
        guard let chatId = chat?.id else { return }

        if let scrollState = self.preloaderHelper.getScrollState(for: chatId) {

            ///Find index of stored first visible item
            if let index = messageTableCellStateArray.firstIndex(where: { $0.getUniqueIdentifier() == scrollState.firstRowId}) {
                ///Scroll to stored first visible item
                collectionView.scrollToItems(at: [IndexPath(item: index, section: 0)], scrollPosition: .top)

                ///Get y position  of first visible item
                if let collectionViewOffsetY = collectionView.item(at: index)?.view.frame.origin.y {

                    ///Scroll to visible item offset
                    let newOffset = collectionViewOffsetY + scrollState.difference - collectionViewScroll.contentInsets.top
                    scrollViewDesiredOffset = newOffset
                    collectionViewScroll.documentYOffset = newOffset

                    if (index == 0 && scrollState.difference == 0) {
                        scrollViewDidScroll()
                    }
                }
            }
        } else {
            let collectionViewContentSize = collectionView.collectionViewLayout?.collectionViewContentSize.height ?? 0
            let offset = collectionViewContentSize - collectionViewScroll.frame.height + collectionViewScroll.contentInsets.top
            scrollViewDesiredOffset = offset
            collectionViewScroll.documentYOffset = offset
            
            delegate?.didScrollToBottom()
        }
    }
    
    func saveScrollPosition() {
        guard let _ = collectionView.enclosingScrollView else { return }
        if collectionView.alphaValue == 0 { return }
        
        guard let chatId = chat?.id else {
            return
        }
        
        let collectionViewOffsetY = collectionViewScroll.documentYOffset + collectionViewScroll.contentInsets.top
        
        ///Find first visible item
        if let firstVisibleRow = collectionView.indexPathForItem(at: NSPoint(x: 0, y: collectionViewOffsetY))?.item {
            ///Find first visible item y position
            if let firstVisibleRowY = collectionView.item(at: firstVisibleRow)?.view.frame.origin.y {
                ///Find unique identifier for first visible item
                let firstRowId = messageTableCellStateArray[firstVisibleRow].getUniqueIdentifier()
                
                ///Save scroll position based on visible item and offset
                self.preloaderHelper.save(
                    firstRowId: firstRowId,
                    difference: collectionViewOffsetY - firstVisibleRowY,
                    for: chatId
                )
            }
        }
    }

}
