//
//  NewChatTableDataSource+RowHeightExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 19/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

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
            let tribeData = (tableCellState.linkTribe?.uuid != nil) ? self.preloaderHelper.tribesData[tableCellState.linkTribe!.uuid] : nil
            let botWebViewData = (tableCellState.messageId != nil) ? self.botsWebViewData[tableCellState.messageId!] : nil
            
            let rowHeight = ChatHelper.getRowHeightFor(
                tableCellState,
                linkData: linkData,
                tribeData: tribeData,
                botWebViewData: botWebViewData,
                collectionViewWidth: collectionView.frame.width
            )
            return CGSize(width: collectionView.frame.width, height: rowHeight)
        }
        
        return CGSize(width: collectionView.frame.width, height: 0.0)
    }
    
}
