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
    @IBOutlet weak var menuBoxContainer: NSBox!
    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var rightLabel: NSTextField!
    
    var menuDataSource: NewMenuItemDataSource? = nil
    
    typealias CollectionViewCell = NewMenuListItem
    
    let menuItems = [
        NewMenuItem(icon: "person", menuTitle: "profile".localized),
        NewMenuItem(icon: "contact", menuTitle: "menu.contacts".localized),
        NewMenuItem(icon: "bottomBar2", menuTitle: "transactions".localized),
        NewMenuItem(icon: "bottomBar4", menuTitle: "request.payment".localized),
        NewMenuItem(icon: "bottomBar1", menuTitle: "pay.invoice".localized),
    ]
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    private func setup() {
        closeButton.cursor = .pointingHand
        
        menuBoxContainer.addShadow(
            offset: CGSize.init(width: 0, height: 0),
            color: NSColor.black,
            opacity: 0.8,
            radius: 35,
            cornerRadius: 0
        )
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
    
    @IBAction func connectWithFriend(_ sender: NSButton) {
        delegate?.buttonClicked(id: 8)
    }
}

import Cocoa

class ScrollDisabledCollectionView: NSCollectionView {
    var disableScroll = true

    override func scrollWheel(with event: NSEvent) {
        if disableScroll {
            return
        } else {
            super.scrollWheel(with: event)
        }
    }
}
