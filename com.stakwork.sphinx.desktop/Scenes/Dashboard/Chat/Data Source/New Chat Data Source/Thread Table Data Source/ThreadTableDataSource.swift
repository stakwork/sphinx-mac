//
//  ThreadTableDataSource.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import WebKit

class ThreadTableDataSource : NewChatTableDataSource {
    
    var threadUUID: String!
    
    init(
        chat: Chat?,
        contact: UserContact?,
        threadUUID: String,
        collectionView: NSCollectionView,
        collectionViewScroll: NSScrollView,
        shimmeringView: ChatShimmeringView,
        headerImage: NSImage?,
        bottomView: NSView,
        webView: WKWebView,
        delegate: NewChatTableDataSourceDelegate?
    ) {
        
        self.threadUUID = threadUUID
        
        super.init(
            chat: chat,
            contact: contact,
            collectionView: collectionView,
            collectionViewScroll: collectionViewScroll,
            shimmeringView: shimmeringView,
            headerImage: headerImage,
            bottomView: bottomView,
            webView: webView,
            delegate: delegate
        )
    }
    
    override func loadMoreItems() {
        ///Nothing to do
    }
    
    override func restorePreloadedMessages() {
        ///Nothing to do
    }

    override func saveMessagesToPreloader() {
        ///Nothing to do
    }

//    override func saveSnapshotCurrentState() {
//    }
    
//    override func restoreScrollLastPosition() {
//
//    }
    
    override func makeCellProvider(
        for collectionView: NSCollectionView
    ) -> DataSource.ItemProvider {
        { (tableView, indexPath, dataSourceItem) -> NSCollectionViewItem in
            return self.getCellFor(
                dataSourceItem: dataSourceItem,
                indexPath: indexPath
            )
        }
    }
}
