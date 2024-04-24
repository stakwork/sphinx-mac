//
//  NewMenuItemDataSource.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 24/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Foundation
import AppKit

protocol NewMenuItemDataSourceDelegate: AnyObject {
    func itemSelected(at index: Int)
}

class NewMenuItemDataSource : NSObject {
    
    weak var delegate: NewMenuItemDataSourceDelegate?
    
    var objects = [NewMenuItem]()
    var collectionView: NSCollectionView! = nil
    var page = 0
    
    init(collectionView: NSCollectionView, delegate: NewMenuItemDataSourceDelegate) {
        super.init()
        self.delegate = delegate
        self.collectionView = collectionView
    }
    
    func updateFrame() {
        self.collectionView.collectionViewLayout?.invalidateLayout()
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

extension NewMenuItemDataSource : NSCollectionViewDataSource {
  
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
  
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return objects.count
    }
  
    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NewMenuListItem"), for: indexPath)
        guard let collectionViewItem = item as? NewMenuListItem else {return item}
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        guard let collectionViewItem = item as? NewMenuListItem else { return }
        
        let object = objects[indexPath.item]
        collectionViewItem.render(with: object)
    }
}

extension NewMenuItemDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let object = objects[indexPath.item]
        return NSSize(width: 200, height: 52)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let indexPath = indexPaths.first, let item = collectionView.item(at: indexPath) as? NewMenuListItem {
            delegate?.itemSelected(at: indexPath.item)
        }
        collectionView.deselectItems(at: indexPaths)
    }
}

struct NewMenuItem {
    let icon: String
    let menuTitle: String
}
