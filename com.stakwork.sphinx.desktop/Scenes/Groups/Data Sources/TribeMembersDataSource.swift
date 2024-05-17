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
    var members = [GroupContact]()
    var pendingMembers = [GroupContact]()
    
    var collectionView: NSCollectionView! = nil
    
    let kCellHeight: CGFloat = 63.0
    
    let kHeaderMargin: CGFloat = 16
    let kHeaderLabelFont = NSFont(name: "Roboto-Medium", size: 14.0)!
    
    var loadingWheel: NSProgressIndicator!
    var loadingWheelContainer: NSView!
    
    var loading = false {
        didSet {
            loadingWheelContainer.isHidden = !loading
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [])
        }
    }
    
    init(
        collectionView: NSCollectionView,
        loadingWheel: NSProgressIndicator,
        loadingWheelContainer: NSView
    ) {
        super.init()
        
        self.collectionView = collectionView
        self.loadingWheel = loadingWheel
        self.loadingWheelContainer = loadingWheelContainer
        
        configureLoadingWheel()
        configureCollectionView()
    }
    
    func updateFrame() {
        self.collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    func configureLoadingWheel() {
        loadingWheelContainer.wantsLayer = true
        loadingWheelContainer.layer?.backgroundColor = NSColor.Sphinx.Body.cgColor
        
        loading = true
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
        self.members.removeAll()
        self.pendingMembers.removeAll()
        
        loadTribeContacts()
    }
    
    
    func loadTribeContacts() {
        guard let id = chat?.id else { return }
        
        API.sharedInstance.getContactsForChat(chatId: id, callback: { [weak self] c in
            guard let self else { return }
            
            loading = false
            
            let (contacts, pendingContacts) = self.getGroupContactsFrom(contacts: c)
            
            self.pendingMembers.append(contentsOf: pendingContacts.sorted(by: { $0.nickname ?? "name.unknown".localized < $1.nickname ?? "name.unknown".localized }))
            self.members.append(contentsOf: contacts.sorted(by: { $0.nickname ?? "name.unknown".localized < $1.nickname ?? "name.unknown".localized }))
            
            self.collectionView.reloadData()
        })
    }
    
    
    func getGroupContactsFrom(contacts: [JSON]) -> ([GroupContact], [GroupContact]) {
        var groupContacts = [GroupContact]()
        var groupPendingContacts = [GroupContact]()
        
        var lastLetter = ""
        
        for contact in  contacts {
            let id = contact.getJSONId()
            let nickname = contact["alias"].stringValue
            let avatarUrl = contact["photo_url"].stringValue
            let isOwner = contact["is_owner"].boolValue
            let pending = contact["pending"].boolValue
            
            if let initial = nickname.first {
                let initialString = String(initial)
            
                var groupContact = GroupContact()
                groupContact.id = id
                groupContact.nickname = nickname
                groupContact.avatarUrl = avatarUrl
                groupContact.isOwner = isOwner
                groupContact.selected = false
                groupContact.firstOnLetter = (initialString != lastLetter)
                
                lastLetter = initialString
                
                if pending {
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
        return numberOfSections()
    }
  
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 && pendingMembers.count > 0 {
            return pendingMembers.count
        } else {
            return members.count
        }
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
        
        if indexPath.section == 0 && pendingMembers.count > 0{
            let object = pendingMembers[indexPath.item]
            collectionViewItem.renderPending(with: object, index: indexPath.item, isLastItem: indexPath.item == pendingMembers.count - 1, itemDelegate: self)
        } else {
            let object = members[indexPath.item]
            collectionViewItem.render(with: object, index: indexPath.item, isLastItem: indexPath.item == members.count - 1, itemDelegate: self)
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        NSSize(width: collectionView.frame.width, height: 30.0)
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        let view = collectionView.makeSupplementaryView(
            ofKind: NSCollectionView.elementKindSectionHeader,
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TribeMemberHeaderView"),
            for: indexPath
        ) as! TribeMemberHeaderView
        
        view.configureWith(
            title: getSectionTitleFor(indexPath.section),
            count: getSectionCountFor(indexPath.section)
        )
        
        return view
    }
    
    func isPendingContactsSection(_ section: Int) -> Bool {
        return pendingMembers.count > 0 && section == 0
    }
    
    func getSectionTitleFor(_ section: Int) -> String {
        return isPendingContactsSection(section) ? "tribe.pending.members.upper".localized : "group.members.upper".localized
    }
    
    func getSectionCountFor(_ section: Int) -> String {
        return isPendingContactsSection(section) ? "\(self.pendingMembers.count)" : "\(self.members.count)"
    }
    
    func numberOfSections() -> Int {
        if pendingMembers.count > 0 {
            return 2
        }
        return 1
    }
}

extension TribeMembersDataSource : NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> NSSize {
        return NSSize(width: collectionView.frame.width, height: kCellHeight)
    }
    
    func collectionView(
        _ collectionView: NSCollectionView,
        didSelectItemsAt indexPaths: Set<IndexPath>
    ) {
        collectionView.deselectItems(at: indexPaths)
    }
}

extension TribeMembersDataSource: GroupContactListItemDelegate {
    func deleteButtonClicked(item: NSCollectionViewItem) {
        guard let index = collectionView.indexPath(for: item)?.item else { return }
        
        AlertHelper.showTwoOptionsAlert(
            title: "kick.member.title".localized,
            message: "kick.member.message".localized,
            confirm: {
                self.loading = true
                
                if let contactId = self.members[index].id {
                    self.didKickContact(contactId: contactId)
                }
            },
            cancel: {},
            confirmLabel: "confirm".localized,
            cancelLabel: "cancel".localized
        )
    }
    
    func showErrorAlert() {
        AlertHelper.showAlert(
            title: "generic.error".localized,
            message: "generic.error.message".localized
        )
    }
    
    func didKickContact(contactId: Int) {
        guard let chat = chat else {
            return
        }
        
        API.sharedInstance.kickMember(chatId: chat.id, contactId: contactId, callback: { [weak self] chatJson in
            guard let self else { return }
            if let chat = Chat.insertChat(chat: chatJson) {
                self.reloadContacts(chat: chat)
                return
            }
            loading = false
            showErrorAlert()
        }, errorCallback: { [weak self] in
            guard let self else { return }
            loading = false
            showErrorAlert()
        })
    }
    
    func approveButtonClicked(item: NSCollectionViewItem) {
        guard let index = collectionView.indexPath(for: item)?.item else { return }
        
        guard let chat = chat, let contactId = self.pendingMembers[index].id else {
            return
        }
        
        guard let message = TransactionMessage.getLastGroupRequestFor(contactId: contactId, in: chat) else {
            return
        }
        
        self.loading = true
        
        respondToRequest(message: message, action: "approved", completion: { [weak self] (chat, message) in
            guard let self else { return }
            self.reloadContacts(chat: chat)
        })
    }
    
    func declineButtonClicked(item: NSCollectionViewItem) {
        guard let index = collectionView.indexPath(for: item)?.item else { return }
        
        guard let chat = chat, let contactId = self.pendingMembers[index].id else {
            return
        }
        
        guard let message = TransactionMessage.getLastGroupRequestFor(contactId: contactId, in: chat) else {
            return
        }
        
        self.loading = true
        
        respondToRequest(message: message, action: "rejected", completion: { [weak self] (chat, message) in
            guard let self else { return }
            self.reloadContacts(chat: chat)
        })
    }
    
    func respondToRequest(
        message: TransactionMessage,
        action: String,
        completion: @escaping (Chat, TransactionMessage) -> ()
    ) {
        API.sharedInstance.requestAction(messageId: message.id, contactId: message.senderId, action: action, callback: { [weak self] json in
            guard let self else { return }
            
            if let chat = Chat.insertChat(
                chat: json["chat"]
            ), let message = TransactionMessage.insertMessage(
                m: json["message"],
                existingMessage: TransactionMessage.getMessageWith(id: json["id"].intValue)
            ).0 {
                completion(chat, message)
                return
            }
            self.loading = false
            self.showErrorAlert()
        }, errorCallback: { [weak self] in
            guard let self else { return }
            self.loading = false
            self.showErrorAlert()
        })
    }
}
