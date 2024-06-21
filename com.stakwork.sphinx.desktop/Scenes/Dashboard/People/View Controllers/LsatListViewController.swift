//
//  LsatListViewController.swift
//  Sphinx
//
//  Created by James Carucci on 5/2/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import Cocoa


class LsatListViewController: NSViewController {
    var lsatList : [LSATObject] = []
    @IBOutlet weak var tableView: NSTableView!
    
    lazy var viewModel : LsatListViewModel = {
        return LsatListViewModel(vc: self, tableView: self.tableView)
    }()
    
    override func viewDidLoad() {
        //self.view.setBackgroundColor(color: NSColor.magenta)
        //self.viewModel?.setupTableView(lsatsList: lsatList)
    }
    
    override func viewWillAppear() {
        self.viewModel.setupTableView(lsatsList: lsatList)
    }
    
    static func instantiate(lsatList:[LSATObject]) -> LsatListViewController {
        let viewController = StoryboardScene.Dashboard.lsatListViewController.instantiate()
        viewController.lsatList = lsatList
        return viewController
    }
}
