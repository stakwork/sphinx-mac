//
//  GroupAddedContactCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 08/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol GroupContactCellDelegate: AnyObject {
    func didDeleteContact(contact: UserContact, item: NSCollectionViewItem)
}

class GroupAddedContactCollectionViewItem: NSCollectionViewItem {
    
    weak var delegate: GroupContactCellDelegate?
    
    @IBOutlet weak var contactImageView: AspectFillNSImageView!
    @IBOutlet weak var closeButton: NSButton!
    @IBOutlet weak var closeLabel: NSTextField!
    @IBOutlet weak var nameLabel: NSTextField!
    
    var groupContact : GroupContact!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeLabel.wantsLayer = true
        closeLabel.layer?.cornerRadius = closeLabel.frame.size.height / 2
    }

    @IBAction func closeButtonClicked(_ sender: Any) {
//        delegate?.didDeleteContact(contact: groupContact.contact, item: self)
    }
    
    func configureFor(groupContact: GroupContact) {
//        self.groupContact = groupContact
//        
//        guard let contact = groupContact.contact else {
//            return
//        }
//        
//        if let imageUrl = contact.avatarUrl?.trim(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
//            MediaLoader.asyncLoadImage(imageView: contactImageView, nsUrl: nsUrl, placeHolderImage: NSImage(named: "profileAvatar"), completion: { image in
//                self.contactImageView.image = image
//            }, errorCompletion: { _ in })
//        } else {
//            contactImageView.image = NSImage(named: "profileAvatar")
//        }
//        
//        nameLabel.stringValue = (contact.nickname ?? "").getFirstNameStyleString()
    }
    
}
