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
        
//        NotificationCenter.default.addObserver(
//            forName: NSScrollView.willStartLiveScrollNotification,
//            object: scrollView,
//            queue: OperationQueue.main
//        ) { [weak self] (n: Notification) in
//            self?.isScrolling = true
//        }
//        
//        NotificationCenter.default.addObserver(
//            forName: NSScrollView.didEndLiveScrollNotification,
//            object: scrollView,
//            queue: OperationQueue.main
//        ) { [weak self] (n: Notification) in
//            self?.isScrolling = false
//        }
    }
    
    func scrollViewDidScroll() {
        MessageOptionsHelper.sharedInstance.hideMenu()
        
        if let scrollViewDesiredOffset = scrollViewDesiredOffset {
            if scrollViewDesiredOffset == collectionViewScroll.documentYOffset {
                collectionView.alphaValue = 1.0
                shimmeringView.isHidden = true
            }
        }
        
//        let difference: CGFloat = 16
//        let scrolledToTop = tableView.contentOffset.y > tableView.contentSize.height - tableView.frame.size.height - difference
//        let scrolledToBottom = tableView.contentOffset.y < -10
//        let didMoveOutOfBottomArea = tableView.contentOffset.y > -10
//
//        if scrolledToTop {
//            didScrollToTop()
//        } else if scrolledToBottom {
//            didScrollToBottom()
//        } else if didMoveOutOfBottomArea {
//            didScrollOutOfBottomArea()
//        }
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
    
    func loadMoreItems() {
//        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: { [weak self] in
//            guard let self = self else { return }
//            self.configureResultsController(items: self.messagesCount + 50)
//        })
    }
}
