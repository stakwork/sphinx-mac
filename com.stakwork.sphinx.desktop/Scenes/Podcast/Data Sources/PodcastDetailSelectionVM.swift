//
//  PodcastDetailSelectionVM.swift
//  Sphinx
//
//  Created by James Carucci on 3/31/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import Cocoa


class PodcastDetailSelectionVM : NSObject{
    weak var collectionView : NSCollectionView?
    weak var vc: PodcastDetailSelectionVC?
    let kCellHeight = 63.0
    let actionsList : [FeedItemActionType] = [
        .copyLink,
        .markAsPlayed
    ]
    
    init(collectionView: NSCollectionView, vc: PodcastDetailSelectionVC) {
        self.collectionView = collectionView
        self.vc = vc
    }
    
    func setupCollectionView(){
        collectionView?.delegate = self
        collectionView?.dataSource = self
    }
    
}


extension PodcastDetailSelectionVM : NSCollectionViewDataSource,NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return actionsList.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastDetailActionCell"), for: indexPath) as! PodcastDetailActionCell
        item.configureView(type: actionsList[indexPath.item])
        
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return CGSize(width: collectionView.frame.width, height: kCellHeight)
    }
    
    
}
