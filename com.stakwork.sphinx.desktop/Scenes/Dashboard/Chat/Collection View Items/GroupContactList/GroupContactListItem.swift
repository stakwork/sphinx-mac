//
//  GroupContactListItem.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 01/05/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

class GroupContactListItem: NSCollectionViewItem {

    @IBOutlet weak var profileImage: NSImageView!
    @IBOutlet weak var contactName: NSTextField!
    @IBOutlet weak var initialName: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.wantsLayer = true
        self.view.layer?.masksToBounds = false
    }
    
    func render(with item: GroupContact) {
        self.profileImage.sd_setImage(with: URL(string: item.contact.avatarUrl ?? ""))
        if let nickName = item.contact.nickname, let char = nickName.first {
            self.initialName.stringValue = item.firstOnLetter ? "\(char)" : ""
            self.contactName.stringValue = nickName
        }
    }
    
}
