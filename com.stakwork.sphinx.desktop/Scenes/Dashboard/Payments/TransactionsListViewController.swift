//
//  TransactionsListViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 22/11/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class TransactionsListViewController: NSViewController {
    
    static func instantiate() -> TransactionsListViewController {
        
        let viewController = StoryboardScene.Payments.transactionsListVC.instantiate()
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
