//
//  NewChatTableDataSource+ScrollExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension NewChatTableDataSource: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        
        collectionView.deselectAll(nil)
        
        if let indexPath = indexPaths.first {
            
            if messageTableCellStateArray.count > indexPath.item {
                let mutableTableCellStateArray = messageTableCellStateArray[indexPath.item]
                
                if let message = mutableTableCellStateArray.message, mutableTableCellStateArray.isThread {
                    delegate?.shouldShowThreadFor(message: message)
                }
            }
        }
        MessageOptionsHelper.sharedInstance.hideMenu()
    }
    
    func addScrollObservers() {
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: collectionViewScroll.contentView,
            queue: OperationQueue.main
        ) { [weak self] (n: Notification) in
            self?.scrollViewDidScroll()
        }
    }
    
    func scrollViewDidScroll() {
        MessageOptionsHelper.sharedInstance.hideMenu()
        
        if let scrollViewDesiredOffset = scrollViewDesiredOffset {
            if scrollViewDesiredOffset == collectionViewScroll.documentYOffset {
                DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: {
                    self.shimmeringView.toggle(show: false)
                    self.collectionView.alphaValue = 1.0
                })
            }
        }
        
        if collectionView.getDistanceToBottom() < 10 {
            didScrollToBottom()
        } else if collectionViewScroll.documentYOffset <= 0 {
            didScrollToTop()
        } else {
            didScrollOutOfBottomArea()
        }
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: NSScrollView) -> Bool {
        return false
    }
    
    func didScrollOutOfBottomArea() {
        scrolledAtBottom = false
        
        delegate?.didScrollOutOfBottomArea()
    }
    
    func didScrollToBottom() {
        if scrolledAtBottom {
            return
        }
        
        scrolledAtBottom = true
        
        delegate?.didScrollToBottom()
    }
    
    func didScrollToTop() {
        if loadingMoreItems {
            return
        }
        
        loadingMoreItems = true
        
        loadMoreItems()
    }
    
    @objc func loadMoreItems() {
        DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: { [weak self] in
            guard let self = self else { return }
            self.configureResultsController(items: self.messagesCount + 50)
        })
    }
    
    @objc func shouldHideNewMsgsIndicator() -> Bool {
        return collectionView.getDistanceToBottom() < 20
    }
}
