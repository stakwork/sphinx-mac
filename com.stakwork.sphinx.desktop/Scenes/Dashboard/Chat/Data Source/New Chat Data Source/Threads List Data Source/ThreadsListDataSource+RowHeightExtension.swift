//
//  ThreadsListDataSource+RowHeightExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension ThreadsListDataSource: NSCollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        if let tableCellState = getTableCellStateFor(
            rowIndex: indexPath.item
        ) {
            let rowHeight = ChatHelper.getThreadListRowHeightFor(
                tableCellState
            )
            return CGSize(width: collectionView.frame.width, height: rowHeight)
        }
        
        return CGSize(width: collectionView.frame.width, height: 0.0)
    }
    
}
