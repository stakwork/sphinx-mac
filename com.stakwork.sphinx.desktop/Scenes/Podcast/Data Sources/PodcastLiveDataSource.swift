//
//  PodcastLiveDataSource.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 17/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PodcastLiveDataSource : NSObject {
    
//    var scrollView: NSScrollView! = nil
//    var collectionView: NSCollectionView! = nil
//    var chat: Chat! = nil
//
//    var messageRows: [TransactionMessageRow] = []
//
//    var visible: Bool = false {
//        didSet {
//            AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
//                self.scrollView.alphaValue = self.visible ? 1.0 : 0.0
//            })
//        }
//    }
//
//    init(collectionView: NSCollectionView,
//         scrollView: NSScrollView,
//         chat: Chat) {
//
//        super.init()
//
//        self.chat = chat
//        self.collectionView = collectionView
//        self.scrollView = scrollView
//
//        self.scrollView.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
//
//        self.collectionView.delegate = self
//        self.collectionView.dataSource = self
//        self.collectionView.reloadData()
//    }
//
//    func resetData() {
//        visible = false
//        messageRows = []
//        collectionView.reloadData()
//    }
//
//    func insert(messages: [TransactionMessage]) {
//        visible = true
//
//        var indexesToInsert = [IndexPath]()
//
//        for m in messages {
//            let messageRow = TransactionMessageRow(message: m)
//            messageRow.isPodcastLive = true
//
//            messageRows.append(messageRow)
//            indexesToInsert.append(IndexPath(item: messageRows.count, section: 0))
//        }
//
//        self.collectionView.insertItems(at: Set(indexesToInsert))
//        self.collectionView.reloadData()
//
//        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
//            self.collectionView.scrollToBottom()
//        })
//    }
}

//extension PodcastLiveDataSource : NSCollectionViewDataSource {
//  
//    func numberOfSections(in collectionView: NSCollectionView) -> Int {
//        return 1
//    }
//  
//    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
//        return messageRows.count + 2
//    }
//  
//    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
//        var item: NSCollectionViewItem! = nil
//        
//        if indexPath.item == 0 || indexPath.item == messageRows.count + 1 {
//            return collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastLiveHeaderCollectionViewItem"), for: indexPath)
//        }
//        
//        let messageRow = messageRows[indexPath.item - 1]
//        let isPodcastBoost = messageRow.isPodcastBoost
//        let received = messageRow.isIncoming()
//        
//        if isPodcastBoost {
//            if received {
//                item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastBoostReceivedCollectionViewItem"), for: indexPath)
//            } else {
//                item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastBoostSentCollectionViewItem"), for: indexPath)
//            }
//        } else {
//            if received {
//                item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageReceivedCollectionViewItem"), for: indexPath)
//            } else {
//                item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageSentCollectionViewItem"), for: indexPath)
//            }
//        }
//        return item
//    }
//    
//    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
//        if let item = item as? MessageRowProtocol {
//            let messageRow = messageRows[indexPath.item - 1]
//            item.configureMessageRow(messageRow: messageRow, contact: nil, chat: chat, chatWidth: self.collectionView.frame.width)
//        }
//    }
//}
//
//extension PodcastLiveDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
//        if indexPath.item == 0 {
//            return NSSize(width: collectionView.frame.width, height: PodcastEpisodesDataSource.kPlayerRowHeight)
//        }
//        if indexPath.item == messageRows.count + 1 {
//            return NSSize(width: collectionView.frame.width, height: 10)
//        }
//        
//        let messageRow = messageRows[indexPath.item - 1]
//        let incoming = messageRow.isIncoming()
//        let isPodcastBoost = messageRow.isPodcastBoost
//        var height: CGFloat = 0.0
//        
//        if isPodcastBoost {
//            height = CommonPodcastBoostCollectionViewItem.getRowHeight()
//        } else {
//            if incoming {
//                height = MessageReceivedCollectionViewItem.getRowHeight(messageRow: messageRow)
//            } else {
//                height = MessageSentCollectionViewItem.getRowHeight(messageRow: messageRow)
//            }
//        }
//        return NSSize(width: collectionView.frame.width, height: height)
//    }
//}
