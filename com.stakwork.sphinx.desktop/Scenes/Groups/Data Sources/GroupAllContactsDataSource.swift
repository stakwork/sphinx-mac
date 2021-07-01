//
//  GroupAllContactsDataSource.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 08/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol GroupAllContactsDSDelegate: AnyObject {
    func didAddedContactWith(id: Int)
    func didRemoveContactWith(id: Int)
    func didToggleAll(selected: Bool)
    func shouldUpdateHeader(allSelected: Bool)
}

class GroupAllContactsDataSource : NSObject {
    
    weak var delegate: GroupAllContactsDSDelegate?
    
    var collectionView : NSCollectionView!
    
    let kCellHeight: CGFloat = 63.0
    let kHeaderHeight: CGFloat = 30.0
    
    var searchTerm = ""
    var tableTitle = ""
    var contacts = [UserContact]()
    var groupContacts = [GroupContact]()
    
    let kGroupMembersMax = 20
    
    init(collectionView: NSCollectionView, delegate: GroupAllContactsDSDelegate?, title: String) {
        super.init()
        self.collectionView = collectionView
        self.delegate = delegate
        self.tableTitle = title
    }
    
    func reloadContacts(contacts: [UserContact]) {
        self.contacts = contacts
        self.processContacts()
        self.collectionView.reloadData()
    }
    
    func processContacts(searchTerm: String = "", selectedContactIds: [Int] = []) {
        self.groupContacts = []
        self.searchTerm = searchTerm
        
        var lastLetter = ""
        
        for contact in  contacts {
            let nickName = contact.getName()
            
            if searchTerm != "" && !nickName.lowercased().contains(searchTerm) {
                continue
            }
            
            if let initial = nickName.first {
                let initialString = String(initial)
            
                var groupContact = GroupContact()
                groupContact.contact = contact
                groupContact.selected = selectedContactIds.contains(contact.id)
                groupContact.firstOnLetter = (initialString != lastLetter)
                
                lastLetter = initialString
                
                groupContacts.append(groupContact)
            }
        }
    }
    
    func unselect(contact: UserContact) {
        toggleSelection(contact: contact, selected: false)
    }
    
    func select(contact: UserContact) {
        toggleSelection(contact: contact, selected: true)
    }
    
    func toggleSelection(contact: UserContact, selected: Bool) {
        let index = groupContacts.firstIndex(where: { (item) -> Bool in
            return item.contact.id == contact.id
        })
        
        if let index = index {
            groupContacts[index].selected = selected
            collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
        }
        updateTableHeader()
    }
    
    func selectAll() {
        let allSelected = areAllSelected()
        
        if groupContacts.count >= (kGroupMembersMax - 1) {
            AlertHelper.showAlert(title: "warning".localized, message: String(format: "add.members.limit".localized, kGroupMembersMax))
            return
        }
        
        for i in 0..<groupContacts.count {
            groupContacts[i].selected = !allSelected
        }
        
        reloadRowsAndHeader()
        delegate?.didToggleAll(selected: !allSelected)
    }
    
    func areAllSelected() -> Bool {
        let selectedCount = groupContacts.filter { $0.selected }.count
        return selectedCount == groupContacts.count
    }
    
    func updateTableHeader() {
        delegate?.shouldUpdateHeader(allSelected: areAllSelected())
    }
    
    func reloadRowsAndHeader() {
        for item in  collectionView.visibleItems() {
            if let item = item as? GroupContactCollectionViewItem, let indexPath = collectionView.indexPath(for: item) {
                let groupContact = groupContacts[indexPath.item]
                item.configureFor(groupContact: groupContact)
            }
        }
        updateTableHeader()
    }
    
    func getSelectedContactsCount() -> Int {
        return groupContacts.filter { $0.selected }.count
    }
}

extension GroupAllContactsDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return CGSize(width: collectionView.frame.width, height: kCellHeight)
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let indexPath = indexPaths.first {
            itemSelectionToggled(collectionView: collectionView, indexPath: indexPath)
        }
    }
    
    func itemSelectionToggled(collectionView: NSCollectionView, indexPath: IndexPath) {
        if let item = collectionView.item(at: indexPath) as? GroupContactCollectionViewItem {
            var groupContact = groupContacts[indexPath.item]
            let contactId = groupContact.contact.id
            let selected = groupContact.selected
            
            if selected {
                groupContact.selected = false
                delegate?.didRemoveContactWith(id: contactId)
            } else {
                if getSelectedContactsCount() >= (kGroupMembersMax - 1) {
                    AlertHelper.showAlert(title: "warning".localized, message: "reach.members.limit".localized)
                    return
                }
                
                groupContact.selected = true
                delegate?.didAddedContactWith(id: contactId)
            }
            
            groupContacts[indexPath.item] = groupContact
            item.configureFor(groupContact: groupContact)
            updateTableHeader()
            
            collectionView.reloadItems(at: [indexPath])
        }
    }
}

extension GroupAllContactsDataSource : NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
 
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return groupContacts.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, willDisplay item: NSCollectionViewItem, forRepresentedObjectAt indexPath: IndexPath) {
        if let item = item as? GroupContactCollectionViewItem {
            let gc = groupContacts[indexPath.item]
            item.configureFor(groupContact: gc)
        }
    }
 
    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        return collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupContactCollectionViewItem"), for: indexPath)
    }
}
