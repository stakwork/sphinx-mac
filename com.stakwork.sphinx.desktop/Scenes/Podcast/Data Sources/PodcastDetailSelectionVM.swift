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
    
    var delegate : PodcastDetailSelectionVCDelegate!
    var episode:PodcastEpisode!
    
    let kCellHeight = 64.0
    
    func getActionsList() -> [FeedItemActionType] {
        return [
            .share,
            episode.wasPlayed ? .markAsUnplayed : .markAsPlayed
        ]
    }
    
    init(
        collectionView: NSCollectionView,
        episode:PodcastEpisode,
        delegate: PodcastDetailSelectionVCDelegate
    ) {
        self.episode = episode
        self.collectionView = collectionView
        self.delegate = delegate
    }
    
    func setupCollectionView(){
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.isSelectable = true
    }
    
    func handleAction(action:FeedItemActionType){
        switch(action){
        case .share:
            if let delegate = delegate {
                delegate.shareButtonTapped(self)
            }
            break
        case .markAsPlayed, .markAsUnplayed:
            if let delegate = delegate {
                episode.wasPlayed = !episode.wasPlayed
                
                delegate.shouldReloadList()
                
                self.collectionView?.reloadData()
            }
            break
        default:
            break
        }
    }
}


extension PodcastDetailSelectionVM : NSCollectionViewDataSource,NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return getActionsList().count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        return collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastDetailActionCell"), for: indexPath) as! PodcastDetailActionCell
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return CGSize(width: collectionView.frame.width, height: kCellHeight)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let indexPath = indexPaths.first {
            handleAction(action: getActionsList()[indexPath.item])
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        if let item = item as? PodcastDetailActionCell {
            item.configureView(type: getActionsList()[indexPath.item])
        }
    }
    
}
