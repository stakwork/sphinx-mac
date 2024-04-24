//
//  NewMenuListView.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 23/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol NewMenuListViewDelegate: AnyObject {
    func closeButtonTapped()
}

class NewMenuListView: NSView, LoadableNib {
    
    weak var delegate: NewMenuListViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var closeButton: CustomButton!
    @IBOutlet weak var menuCollectionView: NSCollectionView!
    
    var menuListDataSource: NewMenuItemDataSource? = nil
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    private func setup() {
        closeButton.cursor = .pointingHand
        let menuItems = [
            NewMenuItem(icon: "person", menuTitle: "My Profile"),
            NewMenuItem(icon: "contact", menuTitle: "Contacts"),
            NewMenuItem(icon: "bottomBar2", menuTitle: "Transactions"),
            NewMenuItem(icon: "bottomBar4", menuTitle: "Request Payment"),
            NewMenuItem(icon: "bottomBar1", menuTitle: "Pay Invoice"),
            NewMenuItem(icon: "mail", menuTitle: "Support")
        ]
        menuListDataSource = NewMenuItemDataSource(tableView: menuCollectionView,
                                                   viewWidth: 262,
                                                   delegate: self,
                                                   menuItems: menuItems)
    }
    
    @IBAction func closeButtonTapped(_ sender: NSButton) {
        delegate?.closeButtonTapped()
    }
    
}

extension NewMenuListView: NewMenuItemDataSourceDelegate {
    func itemSelected(at index: Int) {
        print("Selected item at index: \(index)")
    }
    
    
}
