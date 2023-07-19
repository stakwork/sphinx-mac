//
//  NewChatTableDataSource+ScrollExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension NewChatTableDataSource: NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        if let tableCellState = getTableCellStateFor(
            rowIndex: indexPath.item
        ) {
            let rowHeight = chatHelper.getRowHeightFor(tableCellState)
            return CGSize(width: collectionView.frame.width, height: rowHeight)
        }
        
        return CGSize(width: collectionView.frame.width, height: 100.0)
    }
    
    func scrollViewDidScroll() {
        if let scrollViewDesiredOffset = scrollViewDesiredOffset {
            if scrollViewDesiredOffset == collectionViewScroll.documentYOffset {
                collectionView.alphaValue = 1.0
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
