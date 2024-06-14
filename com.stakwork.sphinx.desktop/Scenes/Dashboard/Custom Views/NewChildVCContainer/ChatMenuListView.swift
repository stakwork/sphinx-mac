//
//  ChatMenuListView.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 12/06/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ChatMenuListView: NSView, LoadableNib {
    
    enum CollectionViewSection: Int, CaseIterable {
        case title
    }
    
    weak var delegate: NewMenuListViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var menuCollectionView: NSCollectionView!
    @IBOutlet weak var menuScrollView: NSScrollView!
    @IBOutlet weak var menuBoxContainer: NSBox!
    
    var menuDataSource: NewChatMenuItemDataSource? = nil
    
    typealias CollectionViewCell = NewMenuListItem
    
    let menuItems = [
        NewMenuItem(icon: "menuIcon", menuTitle: "file".localized),
        NewMenuItem(icon: "bottomBar4", menuTitle: "send".localized),
        NewMenuItem(icon: "bottomBar1", menuTitle: "request".localized),
    ]
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    private func setup() {
        
        menuBoxContainer.addShadow(
            offset: CGSize.init(width: 0, height: 0),
            color: NSColor.black,
            opacity: 0.1,
            radius: 10,
            cornerRadius: 10
        )
        menuBoxContainer.layer?.borderWidth = 1
        menuBoxContainer.layer?.cornerRadius = 10
        let bgColor = NSColor.init(red: 0, green: 0, blue: 0, alpha: 0.1)
        menuBoxContainer.layer?.borderColor = bgColor.cgColor
        menuBoxContainer.layer?.masksToBounds = true
        
    }
    
    func configureDataSource(delegate: NewMenuItemDataSourceDelegate) {
        if menuDataSource == nil {
            menuDataSource = NewChatMenuItemDataSource(collectionView: menuCollectionView, delegate: delegate)
            
        }
        menuDataSource?.setDataAndReload(objects: menuItems)
        // Ensure the collection view is in an NSScrollView
        guard let scrollView = menuCollectionView.enclosingScrollView else {
            print("Collection view is not inside an NSScrollView.")
            return
        }
        
        // Hide the scroll bars
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
    }
}
