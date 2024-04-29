//
//  NewMenuListItem.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 24/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NewMenuListItem: NSCollectionViewItem {

    @IBOutlet weak var itemIcon: NSImageView!
    @IBOutlet weak var itemTitle: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.wantsLayer = true
        self.view.layer?.masksToBounds = false
    }
    
    func render(with item: NewMenuItem) {
        self.itemIcon.image = NSImage(named: item.icon)
        self.itemTitle.stringValue = item.menuTitle
    }
    
}
