//
//  PodcastEpisodesDataSource.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Cocoa

protocol PodcastEpisodesDSDelegate : AnyObject {
    func shouldShareClip(comment: PodcastComment)
    func shouldSendBoost(message: String, amount: Int, animation: Bool) -> TransactionMessage?
}

class PodcastEpisodesDataSource : NSObject {
    
    weak var delegate: PodcastEpisodesDSDelegate?
    
    public static let kPlayerRowHeight: CGFloat = 670
    
    let kRowHeight: CGFloat = 64
    let kHeaderHeight: CGFloat = 60
    
    var collectionView: NSCollectionView! = nil
    var playerHelper: PodcastPlayerHelper! = nil
    var episodes: [PodcastEpisode] = []
    var chat: Chat! = nil
    
    init(collectionView: NSCollectionView,
         chat: Chat,
         episodes: [PodcastEpisode],
         playerHelper: PodcastPlayerHelper,
         delegate: PodcastEpisodesDSDelegate) {
        
        super.init()
        
        PodcastEpisodeCollectionViewItem.podcastImage = nil
        
        self.chat = chat
        self.playerHelper = playerHelper
        self.collectionView = collectionView
        self.episodes = episodes
        self.delegate = delegate
        
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.sectionInset = NSEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.sectionHeadersPinToVisibleBounds = true
        self.collectionView.collectionViewLayout = flowLayout
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.reloadData()
    }
}

extension PodcastEpisodesDataSource : NSCollectionViewDataSource {
  
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 2
    }
  
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return episodes.count
    }
  
    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if indexPath.section == 0 {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastPlayerCollectionViewItem"), for: indexPath)
            return item
        }
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastEpisodeCollectionViewItem"), for: indexPath)
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        if let collectionViewItem = item as? PodcastEpisodeCollectionViewItem {
            let episode = episodes[indexPath.item]
            let isLastRow = indexPath.item == episodes.count - 1
            let isPlaying = (playerHelper.currentEpisode == indexPath.item && playerHelper.isPlaying())
            collectionViewItem.configureWidth(podcast: playerHelper.podcast, and: episode, isLastRow: isLastRow, playing: isPlaying)
        } else if let collectionViewItem = item as? PodcastPlayerCollectionViewItem {
            collectionViewItem.configureWith(playerHelper: playerHelper, chat: chat, delegate: self)
        }
    }
}

extension PodcastEpisodesDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        if indexPath.section == 0 {
            return NSSize(width: self.collectionView.frame.width, height: PodcastEpisodesDataSource.kPlayerRowHeight)
        }
        return NSSize(width: self.collectionView.frame.width, height: kRowHeight)
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        if section == 0 {
            return NSSize.zero
        }
        return NSSize(width: self.collectionView.frame.width, height: kHeaderHeight)
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        let view = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastEpisodesHeaderView"), for: indexPath) as! PodcastEpisodesHeaderView
        view.configureWith(count: episodes.count)
        view.addShadow(location: VerticalLocation.bottom, color: NSColor.black, opacity: 0.2, radius: 3.0)
        return view
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let indexPath = indexPaths.first {
            if indexPath.section == 0 { return }
            
            if let playerView = collectionView.item(at: IndexPath(item: 0, section: 0)) as? PodcastPlayerCollectionViewItem {
                playerView.didTapEpisodeAt(index: indexPath.item)
            }
        }
    }
}

extension PodcastEpisodesDataSource : PodcastPlayerViewDelegate {
    func shouldReloadEpisodesTable() {
        self.collectionView.reloadSections(IndexSet(integer: 1))
    }
    
    func shouldShareClip(comment: PodcastComment) {
        delegate?.shouldShareClip(comment: comment)
    }
    
    func shouldSendBoost(message: String, amount: Int, animation: Bool) -> TransactionMessage? {
        return delegate?.shouldSendBoost(message: message, amount: amount, animation: animation)
    }
    
    func shouldSyncPodcast() {
        chat?.updateMetaData()
    }
}
