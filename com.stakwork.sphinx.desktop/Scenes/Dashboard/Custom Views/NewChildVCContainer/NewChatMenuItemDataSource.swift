//
//  NewChatMenuItemDataSource.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 12/06/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NewChatMenuItemDataSource : NSObject {
    
    weak var delegate: NewMenuItemDataSourceDelegate?
    
    var objects = [NewMenuItem]()
    var collectionView: NSCollectionView! = nil
    var page = 0
    
    init(collectionView: NSCollectionView, delegate: NewMenuItemDataSourceDelegate) {
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
        flowLayout.sectionInset = NSEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        flowLayout.minimumInteritemSpacing = 4.0
        flowLayout.minimumLineSpacing = 4.0
        flowLayout.sectionHeadersPinToVisibleBounds = true
        collectionView.collectionViewLayout = flowLayout
    }
    
    func setDataAndReload(objects: [NewMenuItem]) {
        self.objects.append(contentsOf: objects)
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.reloadData()
    
        self.collectionView.collectionViewLayout?.invalidateLayout()
        self.collectionView.enclosingScrollView?.contentView.scroll(to: NSPoint(x: 0, y: 0))
        
    }
}

extension NewChatMenuItemDataSource : NSCollectionViewDataSource {
  
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
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NewMenuListItem"),
            for: indexPath
        )
        guard let _ = item as? NewMenuListItem else {return item}
        return item
    }
    
    func collectionView(
        _ collectionView: NSCollectionView,
        willDisplay item: NSCollectionViewItem,
        forRepresentedObjectAt indexPath: IndexPath
    ) {
        guard let collectionViewItem = item as? NewMenuListItem else { return }
        
        let object = objects[indexPath.item]
        collectionViewItem.render(with: object)
    }
}

extension NewChatMenuItemDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        return NSSize(width: collectionView.frame.width, height: 40)
    }
    
    func collectionView(
        _ collectionView: NSCollectionView,
        didSelectItemsAt indexPaths: Set<IndexPath>
    ) {
        if let indexPath = indexPaths.first, let _ = collectionView.item(at: indexPath) as? NewMenuListItem {
            delegate?.itemSelected(at: indexPath.item)
        }
        collectionView.deselectItems(at: indexPaths)
    }
}
