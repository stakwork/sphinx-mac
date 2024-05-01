//
//  TribeMembersDataSource.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 01/05/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import AppKit
import SwiftyJSON

class TribeMembersDataSource : NSObject {
    
    var chat: Chat?
    var objects = [GroupContact]()
    
    var groupContacts = [GroupContact]()
    var groupPendingContacts = [GroupContact]()
    
    var collectionView: NSCollectionView! = nil
    var page = 0
    
    init(collectionView: NSCollectionView) {
        super.init()
        self.collectionView = collectionView
        configureCollectionView()
    }
    
    func updateFrame() {
        self.collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.sectionInset = NSEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        flowLayout.minimumInteritemSpacing = 10.0
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.sectionHeadersPinToVisibleBounds = true
        collectionView.collectionViewLayout = flowLayout
    }
    
    func setDataAndReload(objects: Chat) {
        self.chat = objects
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        loadTribeContacts() // Loading the contacts from API
        self.collectionView.collectionViewLayout?.invalidateLayout()
        self.collectionView.enclosingScrollView?.contentView.scroll(to: NSPoint(x: 0, y: 0))
        
    }
    
    
    func loadTribeContacts() {
        guard let id = chat?.id else { return }
        API.sharedInstance.getContactsForChat(chatId: id, callback: { c in
            let (contacts, pendingContacts) = self.getGroupContactsFrom(contacts: c)
            self.objects = (contacts + pendingContacts).sorted(by: {$0.contact.getName().uppercased() > $1.contact.getName().uppercased()})
            self.collectionView.reloadData()
        })
    }
    
    
    func getGroupContactsFrom(contacts: [JSON]) -> ([GroupContact], [GroupContact]) {
        var groupContacts = [GroupContact]()
        var groupPendingContacts = [GroupContact]()
        
        var lastLetter = ""
        
        for newContact in  contacts {
            let contact = UserContact.insertContact(contact: newContact)
            
            if let initial = contact?.nickname?.first {
                let initialString = String(initial)
                let firstOnLetter = (initialString != lastLetter)
                
                let groupContact = GroupContact(contact: contact,
                                                selected: false,
                                                firstOnLetter: firstOnLetter)
                lastLetter = initialString
                
                if let pending = contact?.isPending(), pending {
                    groupPendingContacts.append(groupContact)
                } else {
                    groupContacts.append(groupContact)
                }
            }
        }
        return (groupContacts, groupPendingContacts)
    }
}

extension TribeMembersDataSource : NSCollectionViewDataSource {
  
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
  
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return objects.count
    }
  
    func collectionView(
        _ itemForRepresentedObjectAtcollectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        let item = collectionView.makeItem(
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupContactListItem"),
            for: indexPath
        )
        guard let _ = item as? GroupContactListItem else {return item}
        return item
    }
    
    func collectionView(
        _ collectionView: NSCollectionView,
        willDisplay item: NSCollectionViewItem,
        forRepresentedObjectAt indexPath: IndexPath
    ) {
        guard let collectionViewItem = item as? GroupContactListItem else { return }
        
        let object = objects[indexPath.item]
        collectionViewItem.render(with: object)
    }
}

extension TribeMembersDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        return NSSize(width: collectionView.frame.width, height: 50)
    }
    
    func collectionView(
        _ collectionView: NSCollectionView,
        didSelectItemsAt indexPaths: Set<IndexPath>
    ) {
        collectionView.deselectItems(at: indexPaths)
    }
}
