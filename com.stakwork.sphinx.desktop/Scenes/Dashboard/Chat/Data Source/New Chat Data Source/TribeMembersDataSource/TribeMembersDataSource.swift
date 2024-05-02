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
    
    var loadingWheel: NSProgressIndicator!
    var loadingWheelContainer: NSView!
    
    var loading = false {
        didSet {
            loadingWheelContainer.isHidden = !loading
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [])
        }
    }
    
    init(collectionView: NSCollectionView, loadingWheel: NSProgressIndicator, loadingWheelContainer: NSView) {
        super.init()
        self.collectionView = collectionView
        self.loadingWheel = loadingWheel
        self.loadingWheelContainer = loadingWheelContainer
        loadingWheelContainer.setBackgroundColor(color: NSColor.Sphinx.SecondaryText.withAlphaComponent(0.4))
        loading = true
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
        reloadContacts(chat: objects)
        self.collectionView.allowsMultipleSelection = false
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.collectionView.collectionViewLayout?.invalidateLayout()
        self.collectionView.enclosingScrollView?.contentView.scroll(to: NSPoint(x: 0, y: 0))
        
    }
    
    func reloadContacts(chat: Chat) {
        self.chat = chat
        self.objects.removeAll()
        loadTribeContacts()
        
    }
    
    
    func loadTribeContacts() {
        guard let id = chat?.id else { return }
        API.sharedInstance.getContactsForChat(chatId: id, callback: { [weak self] c in
            guard let self else { return }
            loading = false
            let (contacts, pendingContacts) = self.getGroupContactsFrom(contacts: c)
            self.objects.append(contentsOf: pendingContacts)
            self.objects.append(contentsOf: (contacts).sorted(by: {$0.contact.getName().uppercased() < $1.contact.getName().uppercased()}))
            
            self.collectionView.reloadData()
        })
    }
    
    
    func getGroupContactsFrom(contacts: [JSON]) -> ([GroupContact], [GroupContact]) {
        var groupContacts = [GroupContact]()
        var groupPendingContacts = [GroupContact]()
        
        var lastLetter = ""
        
        for newContact in  contacts {
            let contact = UserContact.insertContact(contact: newContact)
            contact?.updateLastMessage()
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
    
    func showAlert(title: String? = nil, description: String? = nil, actionsTitle: [String] = []) -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = title ?? ""
        alert.informativeText = description ?? ""
        alert.alertStyle = .informational
        
        // Add buttons to the alert
        actionsTitle.forEach { actionTitle in
            alert.addButton(withTitle: actionTitle)
        }
        let response = alert.runModal()
        
        return response
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
        collectionViewItem.render(with: object, index: indexPath.item, itemDelegate: self)
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

extension TribeMembersDataSource: GroupContactListItemDelegate {
    func deleteButtonTapped(index: Int?) {
        guard let index else { return }
        let response = showAlert(
            title: "Delete Contact",
            description: "Are you sure, you want to delete this user?.\nNote this action is not reversible.",
            actionsTitle: ["OK", "Cancel"])
        switch response {
        case .alertFirstButtonReturn:
            loading = true
            if let contact = self.objects[index].contact {
                didKickContact(contact: contact)
            }
            
        default:
            break
        }
    }
    
    func showErrorAler() {
        let response = showAlert(
            title: "Error",
            description: "Unable to delete the user, please try again later",
            actionsTitle: ["OK"])
        switch response {
        default:
            break
        }
    }
    
    func didKickContact(contact: UserContact) {
        if let chat = chat {
            API.sharedInstance.kickMember(chatId: chat.id, contactId: contact.id, callback: { [weak self] chatJson in
                guard let self else { return }
                if let chat = Chat.insertChat(chat: chatJson) {
                    self.reloadContacts(chat: chat)
                    return
                }
                loading = false
                showErrorAler()
            }, errorCallback: { [weak self] in
                guard let self else { return }
                loading = false
                showErrorAler()
            })
        }
    }
}
