//
//  NewChatTableDataSource+RowHeightExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 19/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension NewChatTableDataSource: NSCollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        if let tableCellState = getTableCellStateFor(
            rowIndex: indexPath.item
        ) {
            let linkData = (tableCellState.linkWeb?.link != nil) ? self.preloaderHelper.linksData[tableCellState.linkWeb!.link] : nil
            
            let rowHeight = chatHelper.getRowHeightFor(
                tableCellState,
                and: linkData,
                maxWidth: min(
                    CommonNewMessageCollectionViewitem.kMaximumLabelBubbleWidth,
                    collectionView.frame.width - 80
                )
            )
            return CGSize(width: collectionView.frame.width, height: rowHeight)
        }
        
        return CGSize(width: collectionView.frame.width, height: 0.0)
    }
    
}
