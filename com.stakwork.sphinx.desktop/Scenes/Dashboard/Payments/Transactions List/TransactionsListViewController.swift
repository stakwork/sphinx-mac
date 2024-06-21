//
//  TransactionsListViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 22/11/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class TransactionsListViewController: NSViewController {
    
    @IBOutlet weak var transactionsCollectionView: NSCollectionView!
    @IBOutlet weak var noResultsLabel: NSTextField!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    var transactionsDataSource : TransactionsDataSource!
    
    var page = 1
    var didReachLimit = false
    let itemsPerPage = 50
    
    static func instantiate() -> TransactionsListViewController {
        
        let viewController = StoryboardScene.Payments.transactionsListVC.instantiate()
        
        return viewController
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [])
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        transactionsCollectionView.alphaValue = 0.0
        noResultsLabel.alphaValue = 0.0
        configureCollectionView()
    }
    
    func configureCollectionView() {
        transactionsDataSource = TransactionsDataSource(collectionView: transactionsCollectionView, delegate: self)
        transactionsCollectionView.delegate = transactionsDataSource
        transactionsCollectionView.dataSource = transactionsDataSource
        
        loading = true

        API.sharedInstance.getTransactionsList(page: page, itemsPerPage: itemsPerPage, callback: { transactions in
            self.setNoResultsLabel(count: transactions.count)
            self.checkResultsLimit(count: transactions.count)
            self.transactionsDataSource.loadTransactions(transactions: transactions)
            self.loading = false
        }, errorCallback: {
            self.checkResultsLimit(count: 0)
            self.transactionsCollectionView.alphaValue = 0.0
            self.loading = false
            
            AlertHelper.showAlert(
                title: "generic.error.title".localized,
                message: "error.loading.transactions".localized
            )
        })
    }
    
    func setNoResultsLabel(count: Int) {
        noResultsLabel.alphaValue = count > 0 ? 0.0 : 1.0
    }
    
    func checkResultsLimit(count: Int) {
        didReachLimit = count < itemsPerPage
    }
    
    deinit {
        print("here is the TransactionsListViewController going to sleep")
    }
}

extension TransactionsListViewController : TransactionsDataSourceDelegate {
    func shouldLoadMoreTransactions() {
        if didReachLimit {
            return
        }
        
        page = page + 1
        
        API.sharedInstance.getTransactionsList(page: page, itemsPerPage: itemsPerPage, callback: { transactions in
            self.checkResultsLimit(count: transactions.count)
            self.transactionsDataSource.addMoreTransactions(transactions: transactions)
        }, errorCallback: { })
    }
}
