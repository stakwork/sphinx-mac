//
//  PaymentTemplatesDataSource.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol PaymentTemplatesDSDelegate: AnyObject {
    func didSelectImage(image: ImageTemplate?)
}

class PaymentTemplatesDataSource : NSObject {
    
    weak var delegate: PaymentTemplatesDSDelegate?
    
    var collectionView : NSCollectionView!
    
    public static let kCellHeight: CGFloat = 75.0
    public static let kCellWidth: CGFloat = 68.0
    
    var images = [ImageTemplate]()
    var selectedRow = 0
    
    init(collectionView: NSCollectionView, delegate: PaymentTemplatesDSDelegate, images: [ImageTemplate]) {
        super.init()
        
        collectionView.isSelectable = true
        
        self.delegate = delegate
        self.collectionView = collectionView
        self.images = images
        
        NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification, object: self.collectionView.enclosingScrollView?.contentView, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.scrollViewDidScroll()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: nil)
    }
}

extension PaymentTemplatesDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        
        if indexPath.item == 0 {
            let sideInset = self.collectionView.bounds.width / 2 - PaymentTemplatesDataSource.kCellWidth / 2
            return CGSize(width: sideInset, height: PaymentTemplatesDataSource.kCellHeight)
        } else if indexPath.item == images.count + 2 {
            let sideInset = self.collectionView.bounds.width / 2 - PaymentTemplatesDataSource.kCellWidth / 2
            return CGSize(width: sideInset, height: PaymentTemplatesDataSource.kCellHeight)
        } else if indexPath.item > 0 {
            return CGSize(width: PaymentTemplatesDataSource.kCellWidth, height: PaymentTemplatesDataSource.kCellHeight)
        } else {
            return CGSize(width: PaymentTemplatesDataSource.kCellWidth, height: PaymentTemplatesDataSource.kCellHeight)
        }
    }
}

extension PaymentTemplatesDataSource : NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
 
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count + 3
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        if let item = item as? TemplateCollectionViewItem {
            if indexPath.item == 0 {
                item.configureAsMargin()
            } else if indexPath.item == images.count + 2 {
                item.configureAsMargin()
            } else if indexPath.item == 1 {
                item.configure(itemIndex: indexPath.item, imageTemplate: nil)
            } else {
                item.configure(itemIndex: indexPath.item, imageTemplate: images[indexPath.item - 2])
            }
        }
    }
 
    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        return collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TemplateCollectionViewItem"), for: indexPath)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let firstIndexPath = indexPaths.first {
            collectionView.scrollToIndex(targetIndex: firstIndexPath.item + 1, animated: true, position: .centeredHorizontally)
            
            selectedRow = firstIndexPath.item

            let image = (selectedRow > 1 && selectedRow - 2 < images.count) ? images[selectedRow - 2] : nil
            delegate?.didSelectImage(image: image)
        }
    }
}

extension PaymentTemplatesDataSource {
    func scrollViewDidScroll() {
        if let centerIndexPath = getCenterClosestIndexPath() {
            if selectedRow == centerIndexPath.item {
                return
            }

            selectedRow = centerIndexPath.item

            let image = (selectedRow > 1 && selectedRow - 2 < images.count) ? images[selectedRow - 2] : nil
            delegate?.didSelectImage(image: image)
        }
    }
    
    func didFinishScrolling() {
        if let indexPath = getCenterClosestIndexPath() {
            collectionView.scrollToIndex(targetIndex: indexPath.item + 1, animated: true, position: .centeredHorizontally)
        }
    }
    
    func getCenterClosestIndexPath() -> IndexPath? {
        guard let scrollView = collectionView.enclosingScrollView else {
            return nil
        }
        
        if collectionView.visibleItems().count == 0 {
            return nil
        }

        var closestItem: NSCollectionViewItem = collectionView.visibleItems()[0]

        for item in collectionView.visibleItems() as [NSCollectionViewItem] {
            if let item = item as? TemplateCollectionViewItem {

                let closestItemCenterX = closestItem.view.frame.origin.x + (closestItem.view.frame.width / 2)
                let closestItemDelta = abs(closestItemCenterX - scrollView.bounds.size.width/2.0 - scrollView.contentView.bounds.origin.x)

                let itemCenterX = item.view.frame.origin.x + (item.view.frame.width / 2)
                let itemDelta = abs(itemCenterX - scrollView.bounds.size.width/2.0 - scrollView.contentView.bounds.origin.x)
                
                if (itemDelta < closestItemDelta){
                    closestItem = item
                }
            }
        }
        
        if let centerIndexPath = collectionView.indexPath(for: closestItem) {
            return centerIndexPath
        }

        return nil
    }
}
