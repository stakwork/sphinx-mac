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
    func getActionsList()->[FeedItemActionType]{
        return [
            .share,
            (vc?.episode.wasPlayed ?? false) ? .markAsUnplayed : .markAsPlayed
        ]
    }
    
    init(collectionView: NSCollectionView, vc: PodcastDetailSelectionVC) {
        self.collectionView = collectionView
        self.vc = vc
    }
    
    func setupCollectionView(){
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.isSelectable = true
    }
    
    func handleAction(action:FeedItemActionType){
        switch(action){
        case .share:
            if let valid_vc = vc?.delegate as? PodcastEpisodeCollectionViewItem{
                valid_vc.shareButtonTapped(self)
            }
            break
        case .markAsPlayed:
            if let valid_vc = vc?.delegate as? PodcastEpisodeCollectionViewItem{
                valid_vc.toggleWasPlayed()
                self.collectionView?.reloadData()
            }
            break
        case .markAsUnplayed:
            if let valid_vc = vc?.delegate as? PodcastEpisodeCollectionViewItem{
                valid_vc.toggleWasPlayed()
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
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastDetailActionCell"), for: indexPath) as! PodcastDetailActionCell
        item.configureView(type: getActionsList()[indexPath.item])
        
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return CGSize(width: collectionView.frame.width, height: kCellHeight)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let indexPath = indexPaths.first {
            handleAction(action: getActionsList()[indexPath.item])
        }
    }
    
}
