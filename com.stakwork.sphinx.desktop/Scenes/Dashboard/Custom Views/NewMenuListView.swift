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
    func buttonClicked(id: Int)
}

class NewMenuListView: NSView, LoadableNib {
    
    enum CollectionViewSection: Int, CaseIterable {
        case title
    }
    
    weak var delegate: NewMenuListViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var closeButton: CustomButton!
    @IBOutlet weak var menuCollectionView: NSCollectionView!
    @IBOutlet weak var menuScrollView: NSScrollView!
    
    var menuDataSource: NewMenuItemDataSource? = nil
    
    typealias CollectionViewCell = NewMenuListItem
    
    let menuItems = [
        NewMenuItem(icon: "person", menuTitle: "My Profile"),
        NewMenuItem(icon: "contact", menuTitle: "Contacts"),
        NewMenuItem(icon: "bottomBar2", menuTitle: "Transactions"),
        NewMenuItem(icon: "bottomBar4", menuTitle: "Request Payment"),
        NewMenuItem(icon: "bottomBar1", menuTitle: "Pay Invoice"),
        NewMenuItem(icon: "mail", menuTitle: "Support")
    ]
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
        menuCollectionView.layer?.backgroundColor = NSColor.Sphinx.Body.cgColor
    }
    
    private func setup() {
        closeButton.cursor = .pointingHand
    }
    
    func configureDataSource(delegate: NewMenuItemDataSourceDelegate) {
        if menuDataSource == nil {
            menuDataSource = NewMenuItemDataSource(collectionView: menuCollectionView, delegate: delegate)
            
        }
        menuDataSource?.setDataAndReload(objects: menuItems)
    }
    
    @IBAction func closeButtonTapped(_ sender: NSButton) {
        delegate?.closeButtonTapped()
    }
    
    @IBAction func addFriendButtonTapped(_ sender: NSButton) {
        delegate?.buttonClicked(id: 6)
    }
    
    @IBAction func createTribeButtonTapped(_ sender: NSButton) {
        delegate?.buttonClicked(id: 7)
    }
}
