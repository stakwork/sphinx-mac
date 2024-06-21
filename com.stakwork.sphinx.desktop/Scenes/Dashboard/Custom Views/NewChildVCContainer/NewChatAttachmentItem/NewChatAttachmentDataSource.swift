//
//  NewChatAttachmentDataSource.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 13/06/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NewChatAttachmentDataSource : NSObject {
    
    var delegate: NewChatAttachmentDelegate?
    
    var objects = [NewAttachmentItem]()
    var collectionView: NSCollectionView! = nil
    var page = 0
    
    init(collectionView: NSCollectionView, delegate: NewChatAttachmentDelegate) {
        super.init()
        self.delegate = delegate
        self.collectionView = collectionView
        configureCollectionView()
    }
    
    func updateFrame() {
        self.collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.sectionInset = NSEdgeInsets(top: -10.0, left: 0.0, bottom: 10.0, right: 0.0)
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.minimumLineSpacing = 12.0
        flowLayout.sectionHeadersPinToVisibleBounds = true
        flowLayout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = flowLayout
    }
    
    func setDataAndReload(objects: [NewAttachmentItem]) {
        self.objects = objects
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.reloadData()
    
        self.collectionView.collectionViewLayout?.invalidateLayout()
        self.collectionView.enclosingScrollView?.contentView.scroll(to: NSPoint(x: 0, y: 0))
        
    }
}

extension NewChatAttachmentDataSource : NSCollectionViewDataSource {
  
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
  
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return objects.count
    }
  
    func collectionView(
        _ itemForRepresentedObjectAtcollectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        let item = collectionView.makeItem(
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NewChatAttachmentListItem"),
            for: indexPath
        )
        guard let _ = item as? NewChatAttachmentListItem else {return item}
        return item
    }
    
    func collectionView(
        _ collectionView: NSCollectionView,
        willDisplay item: NSCollectionViewItem,
        forRepresentedObjectAt indexPath: IndexPath
    ) {
        guard let collectionViewItem = item as? NewChatAttachmentListItem else { return }
        
        let object = objects[indexPath.item]
        collectionViewItem.render(with: object)
        collectionViewItem.currentIndex = indexPath.item
        collectionViewItem.delegate = delegate
    }
}

extension NewChatAttachmentDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        return NSSize(width: 140, height: 140)
    }
    
    func collectionView(
        _ collectionView: NSCollectionView,
        didSelectItemsAt indexPaths: Set<IndexPath>
    ) {
        collectionView.deselectItems(at: indexPaths)
    }
}

extension NewChatAttachmentDataSource : NewChatAttachmentDelegate {
    func closePreview(at index: Int?) {
        if let index {
            delegate?.closePreview(at: index)
        }
    }
    
    func playPreview(of data: Data?) {
        delegate?.playPreview(of: data)
    }
    
}
