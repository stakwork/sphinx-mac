//
//  GiphySearchDataSource.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 09/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol GiphySearchDataSourceDelegate: AnyObject {
    func didSelectGiphy(object: GiphyObject, data: Data)
    func shouldAddObjects(type: GiphyHelper.SearchType, page: Int)
}

class GiphySearchDataSource : NSObject {
    
    weak var delegate: GiphySearchDataSourceDelegate?
    
    var objects = [GiphyObject]()
    var collectionView: NSCollectionView! = nil
    var searchType = GiphyHelper.SearchType.Gifs
    var insertingRows = false
    var page = 0
    
    init(collectionView: NSCollectionView, delegate: GiphySearchDataSourceDelegate, searchType: GiphyHelper.SearchType) {
        super.init()
        self.delegate = delegate
        self.collectionView = collectionView
        self.searchType = searchType
    }
    
    func updateFrame() {
        self.collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    func setDataAndReload(objects: [GiphyObject]) {
        self.page = 0
        self.objects = objects
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.reloadData()
    
        self.collectionView.collectionViewLayout?.invalidateLayout()
        self.collectionView.enclosingScrollView?.contentView.scroll(to: NSPoint(x: 0, y: 0))
        
        NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: collectionView.enclosingScrollView?.contentView, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.scrollViewDidScroll()
        }
    }
    
    func insertObjects(objects: [GiphyObject]) {
        let indexesToInsert = getIndexesToInsert(start: self.objects.count, count: objects.count)
        self.objects.append(contentsOf: objects)
        collectionView.insertItems(at: Set(indexesToInsert))
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
            self.insertingRows = false
        }
    }
    
    func getIndexesToInsert(start: Int, count: Int) -> [IndexPath] {
        var indexes = [IndexPath]()
        for i in start..<start + count {
            indexes.append(IndexPath(item: i, section: 0))
        }
        return indexes
    }
    
    func updateDataAndReload(objects: [GiphyObject]) {
        self.objects = objects
        self.collectionView.reloadSections(IndexSet(integer: 0))
    }
}

extension GiphySearchDataSource : NSCollectionViewDataSource {
  
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
  
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return objects.count
    }
  
    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GiphySearchCollectionViewItem"), for: indexPath)
        guard let collectionViewItem = item as? GiphySearchCollectionViewItem else {return item}
        collectionViewItem.isSelected = false
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        guard let collectionViewItem = item as? GiphySearchCollectionViewItem else { return }
        
        let object = objects[indexPath.item]
        collectionViewItem.loadObject(object)
    }
}

extension GiphySearchDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let object = objects[indexPath.item]
        let height:CGFloat = object.isGif() ? GiphyHelper.kGifItemHeight : GiphyHelper.kStickerItemHeight
        let width = object.adaptedWidth ?? height * CGFloat(object.aspectRatio)
        return NSSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let indexPath = indexPaths.first, let item = collectionView.item(at: indexPath) as? GiphySearchCollectionViewItem {
            if let data = item.gifData {
                let object = objects[indexPath.item]
                delegate?.didSelectGiphy(object: object, data: data)
            }
        }
    }
}

extension GiphySearchDataSource {
    func scrollViewDidScroll() {
        guard let scrollView = collectionView.enclosingScrollView else {
            return
        }
        
        if searchType == .Recent {
            return
        }
        
        if scrollView.contentView.bounds.origin.y >= (collectionView.bounds.height - scrollView.frame.size.height) && !insertingRows {
            insertingRows = true
            
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.page = self.page + 1
                self.delegate?.shouldAddObjects(type: self.searchType, page: self.page)
            })
        }
    }
}
