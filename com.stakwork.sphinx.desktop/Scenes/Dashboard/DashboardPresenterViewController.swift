//
//  DashboardPresenterViewController.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 11/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol DashboardPresenterDelegate: AnyObject {
    func dismissPresenter()
}

class DashboardPresenterViewController: NSViewController {

    @IBOutlet weak var vcTitle: NSText!
    weak var delegate: DashboardPresenterDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
    }
    
    func configureHeaderTitle(tittle: String) {
        
    }
    
    func configurePresenterVC() {
        
    }
    
    func dismissVC() {
        delegate?.dismissPresenter()
    }
    
    deinit {
        print("I am going to sleep")
    }
    
}
