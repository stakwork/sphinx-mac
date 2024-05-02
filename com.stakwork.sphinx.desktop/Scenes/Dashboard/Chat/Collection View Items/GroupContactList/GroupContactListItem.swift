//
//  GroupContactListItem.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 01/05/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

protocol GroupContactListItemDelegate: AnyObject {
    func deleteButtonTapped(index: Int?)
}

class GroupContactListItem: NSCollectionViewItem {

    @IBOutlet weak var profileImage: ChatSmallAvatarView!
    @IBOutlet weak var contactName: NSTextField!
    @IBOutlet weak var initialName: NSTextField!
    @IBOutlet weak var deleteButton: NSView!
    
    var currentIndex: Int?
    var delegate: GroupContactListItemDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        setup()
    }
    
    func setup() {
        self.view.wantsLayer = true
        self.view.layer?.masksToBounds = false
    }
    
    func render(with item: GroupContact,
                index: Int? = nil,
                itemDelegate: GroupContactListItemDelegate? = nil) {
        currentIndex = index
        delegate = itemDelegate
        
        if let nickName = item.contact.nickname, let char = nickName.first {
            self.initialName.stringValue = item.firstOnLetter ? "\(char)".uppercased() : ""
            self.contactName.stringValue = nickName.capitalized
            
            profileImage.configureForUserWith(
                color: item.contact.getColor(),
                alias: item.contact.nickname,
                picture: item.contact.avatarUrl,
                radius: 16
            )
            deleteButton.isHidden = (index ?? 0) == 0
        }
    }
    
    @IBAction func deleteTapped(_ button: NSButton) {
        delegate?.deleteButtonTapped(index: currentIndex)
    }
    
}
