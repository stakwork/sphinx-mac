//
//  GroupContactCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 08/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

struct GroupContact {
    var contact: UserContact! = nil
    var selected: Bool = false
    var firstOnLetter: Bool = false
}

class GroupContactCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var letterLabel: NSTextField!
    @IBOutlet weak var contactNameLabel: NSTextField!
    @IBOutlet weak var contactImageView: AspectFillNSImageView!
    @IBOutlet weak var checkboxLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configureFor(groupContact: GroupContact) {
        guard let contact = groupContact.contact else {
            return
        }
        
        contactImageView.radius = contactImageView.frame.height / 2
        contactNameLabel.stringValue = contact.getName()
        
        if let imageUrl = contact.avatarUrl?.trim(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
            MediaLoader.asyncLoadImage(imageView: contactImageView, nsUrl: nsUrl, placeHolderImage: NSImage(named: "profileAvatar"), completion: { image in
                self.contactImageView.image = image
            }, errorCompletion: { _ in })
        } else {
            contactImageView.image = NSImage(named: "profileAvatar")
        }
        
        configureInitial(nickname: contact.nickname, firstOnLetter: groupContact.firstOnLetter)
        configureCheckbox(selected: groupContact.selected)
    }
    
    func hideCheckBox() {
        checkboxLabel.isHidden = true
    }
    
    func configureCheckbox(selected: Bool) {
        checkboxLabel.stringValue = selected ? "" : ""
        checkboxLabel.textColor = NSColor(hex: selected ? "#618aff" : "#e4e7ea")
    }
    
    func configureInitial(nickname: String?, firstOnLetter: Bool) {
        letterLabel.stringValue = String(nickname?.first ?? ("name.unknown".localized.first ?? "U"))
        letterLabel.isHidden = !firstOnLetter
    }
    
}
