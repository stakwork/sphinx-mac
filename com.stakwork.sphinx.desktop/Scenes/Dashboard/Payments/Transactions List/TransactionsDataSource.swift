//
//  TransactionsListDataSource.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 22/11/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol TransactionsDataSourceDelegate: AnyObject {
    func shouldLoadMoreTransactions()
}

class TransactionsDataSource : NSObject {
    
    weak var delegate: TransactionsDataSourceDelegate?
    
    var collectionView : NSCollectionView!
    
    var transactions = [PaymentTransaction]()
    
    var insertingRows = false
    
    var shouldShowLoadingWheel = true
    
    ///Constants
    let kViewWidth: CGFloat = 450.0
    let kViewDefaultHeight: CGFloat = 80.0
    let kErrorMessageHorizontalMargins: CGFloat = 71.0
    let kErrorMessageBottomMargin: CGFloat = 22.0
    
    init(
        collectionView: NSCollectionView,
        delegate: TransactionsDataSourceDelegate
    ) {
        super.init()
        
        self.collectionView = collectionView
        self.delegate = delegate
        
        collectionView.registerItem(LoadingMoreCollectionViewItem.self)
        collectionView.registerItem(TransactionCollectionViewItem.self)
        
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: collectionView.enclosingScrollView?.contentView,
            queue: OperationQueue.main
        ) { [weak self] (n: Notification) in
            self?.scrollViewDidScroll()
        }
    }
    
    func loadTransactions(transactions: [PaymentTransaction]) {
        self.shouldShowLoadingWheel = (transactions.count > 0 && transactions.count % 50 == 0)
        self.transactions = transactions
        
        self.collectionView.alphaValue = 1.0
        self.collectionView.reloadData()
    }
    
    func addMoreTransactions(transactions: [PaymentTransaction]) {
        shouldShowLoadingWheel = (transactions.count > 0 && transactions.count % 50 == 0)
        insertObjectsToModel(transactions: transactions)
        collectionView.reloadData()
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
            self.insertingRows = false
        }
    }
    
    func insertObjectsToModel(transactions: [PaymentTransaction]) {
        self.transactions.append(contentsOf: transactions)
    }
}

extension TransactionsDataSource : NSCollectionViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else {
            return
        }
        
        let transaction = transactions.count > indexPath.item ? transactions[indexPath.item] : nil
        
        if !transaction!.isFailed() {
            return
        }
        
        transaction?.expanded = !(transaction?.expanded ?? false)

        AnimationHelper.animateViewWith(duration: 0.2, animationsBlock: {
            collectionView.reloadItems(at: [indexPath])
        }, completion: {})
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        if let item = item as? LoadingMoreCollectionViewItem {
            item.configureCell(text: "loading.more.transactions".localized)
        } else if let item = item as? TransactionCollectionViewItem {
            let transaction = transactions[indexPath.item]
            item.configureCell(transaction: transaction)
        }
    }
}

extension TransactionsDataSource : NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let transaction = transactions.count > indexPath.item ? transactions[indexPath.item] : nil
        
        if let transaction = transaction, transaction.expanded {
            
            let textHeight = ChatHelper.getTextHeightFor(
                text: transaction.errorMessage ?? "",
                width: kViewWidth - kErrorMessageHorizontalMargins,
                font: NSFont(name: "Roboto-Regular", size: 14.0)!,
                labelMargins: kErrorMessageBottomMargin
            )
            
            return NSSize(width: collectionView.frame.size.width, height: kViewDefaultHeight + textHeight)
        } else {
            return NSSize(width: collectionView.frame.size.width, height: kViewDefaultHeight)
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}

extension TransactionsDataSource : NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return shouldShowLoadingWheel ? transactions.count + 1 : transactions.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if indexPath.item == transactions.count {
            
            let item = collectionView.makeItem(
                withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LoadingMoreCollectionViewItem"), 
                for: indexPath
            ) as! LoadingMoreCollectionViewItem
            
            return item
        }

        let item = collectionView.makeItem(
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TransactionCollectionViewItem"),
            for: indexPath
        ) as! TransactionCollectionViewItem
        
        return item
    }
}

extension TransactionsDataSource {
    func scrollViewDidScroll() {
        if collectionView.getDistanceToBottom() < 60 && !insertingRows {
            insertingRows = true

            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.delegate?.shouldLoadMoreTransactions()
            })
        }
    }
}
