//
//  GroupAddedContactsDataSource.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 08/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class GroupAddedContactsDataSource: NSObject {
    
    weak var delegate: GroupContactCellDelegate?
    
    var collectionView : NSCollectionView!
    
    let kCellHeight: CGFloat = 90.0
    let kCellWidth: CGFloat = 78.0
    
    var searchTerm = ""
    var contacts = [GroupContact]()
    var selectedContactIds = [Int]()
    
    init(collectionView: NSCollectionView, delegate: GroupContactCellDelegate) {
        super.init()
        
        self.delegate = delegate
        self.collectionView = collectionView
    }
    
    func addExistingContacts(contacts: [UserContact]) {
        let groupContacts = contacts.map { GroupContact(contact: $0) }
        self.contacts.append(contentsOf: groupContacts)
    }
    
    func addContact(contact: UserContact) {
        self.contacts.append(GroupContact(contact: contact))
        
        let numberOfRow = self.collectionView.numberOfItems(inSection: 0)
        self.collectionView.insertItems(at: [IndexPath(item: numberOfRow, section: 0)])
    }
    
    func addAll(contacts: [UserContact?]) {
        self.contacts = []
        
        for contact in contacts {
            addContact(contact: contact)
        }
        self.collectionView.reloadData()
    }
    
    func removeContact(contact: UserContact) {
        let index = contacts.firstIndex(where: { (item) -> Bool in
            return item.contact.id == contact.id
        })
        
        if let index = index {
            self.contacts.remove(at: index)
            self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        }
    }
    
    func removeAll() {
        self.contacts = []
        self.collectionView.reloadData()
    }
    
    func addContact(contact: UserContact?) {
        if let contact = contact {
            self.contacts.append(GroupContact(contact: contact))
        }
    }
}

extension GroupAddedContactsDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
   func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
       return CGSize(width: kCellWidth, height: kCellHeight)
   }
}

extension GroupAddedContactsDataSource : NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return contacts.count
    }

    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        if let item = item as? GroupAddedContactCollectionViewItem {
            let groupContact = contacts[indexPath.item]
            item.delegate = delegate
            item.configureFor(groupContact: groupContact)
        }
    }

    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        return collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupAddedContactCollectionViewItem"), for: indexPath)
    }
}
