//
//  ContactsService.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreData

public final class ContactsService {
    
    public var contacts = [UserContact]()
    public var chats = [Chat]()
    public var chatListObjects = [ChatListCommonObject]()
    public var subscriptions = [Subscription]()
    
    public var chatsCount = 0
    
    init() {
        reload()
    }
    
    var lastContactsUpdateDate: Date? {
        get {
            return UserDefaults.Keys.lastContactsUpdateDate.get(defaultValue: nil)
        }
        set {
            UserDefaults.Keys.lastContactsUpdateDate.set(newValue)
        }
    }
    
    public func reload() {
        updateContacts()
        updateChats()
        updateSubscriptions()
    }
    
    public func updateContacts() {
        let contactIds = ((Chat.getAllConversations().map { $0.contactIds }).flatMap { $0 }).map { $0.intValue }
        self.contacts = UserContact.getAllExcluding(ids: contactIds)
    }
    
    public func updateChats() {
        self.chats = Chat.getAll()
    }
    
    public func updateSubscriptions() {
        self.subscriptions = Subscription.getAll()
    }
    
    func resetContactsUpdateDateIfNeeded() {
        let savedAppVersion: Int? = UserDefaults.Keys.appVersion.get()
        let appVersion = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0
        
        if savedAppVersion == nil || savedAppVersion! < appVersion {
            lastContactsUpdateDate = nil
        }
        UserDefaults.Keys.appVersion.set(appVersion)
    }
    
    public func insertObjects(contacts: [JSON], chats: [JSON], subscriptions: [JSON], invites: [JSON]) {
        resetContactsUpdateDateIfNeeded()
        
        insertContacts(contacts: contacts)
        insertChats(chats: chats)
        insertSubscriptions(subscriptions: subscriptions)
        insertInvites(invites: invites)
        
        if contacts.count > 0 || chats.count > 0 {
            lastContactsUpdateDate = Date()
        }
    }
    
    public func insertContact(contact: JSON, pin: String? = nil) {
        let (c, _) = UserContact.insertContact(contact: contact)
        c?.pin = pin
        c?.saveContact()
    }
    
    public func insertContacts(contacts: [JSON]) {
        if contacts.count > 0 {
            var didDeleteContacts = false
            
            for contact: JSON in contacts {
                if let id = contact.getJSONId(), contact["deleted"].boolValue || contact["from_group"].boolValue {
                    if let contact = UserContact.getContactWith(id: id) {
                        didDeleteContacts = true
                        CoreDataManager.sharedManager.deleteContactObjectsFor(contact)
                    }
                } else {
                    let _ = UserContact.insertContact(contact: contact, referenceDate: lastContactsUpdateDate)
                }
            }
            
            if didDeleteContacts {
                NotificationCenter.default.post(name: .shouldResetChat, object: nil)
            }
        }
    }
    
    public func insertInvites(invites: [JSON]) {
        if invites.count > 0 {
            
            for invite: JSON in invites {
                let _ = UserInvite.insertInvite(invite: invite)
            }
        }
    }
    
    public func insertChats(chats: [JSON]) {
        if chats.count > 0 {
            var didDeleteChats = false
            
            for chat: JSON in chats {
                if let id = chat.getJSONId(), chat["deleted"].boolValue {
                    if let chat = Chat.getChatWith(id: id) {
                        didDeleteChats = true
                        CoreDataManager.sharedManager.deleteChatObjectsFor(chat)
                    }
                } else {
                    if let chat = Chat.insertChat(chat: chat, referenceDate: lastContactsUpdateDate) {
                        if chat.seen {
                            chat.setChatMessagesAsSeen(shouldSync: false, shouldSave: false)
                        }
                    }
                }
            }
            
            if didDeleteChats {
                NotificationCenter.default.post(name: .shouldResetChat, object: nil)
            }
        }
    }
    
    public func insertSubscriptions(subscriptions: [JSON]) {
        if subscriptions.count > 0 {
            for subscription: JSON in subscriptions {
                let _ = Subscription.insertSubscription(subscription: subscription)
            }
        }
    }
    
    public func getChatListObjects() -> [ChatListCommonObject] {
        let filteredContacts =  contacts.filter { !$0.isOwner && !$0.shouldBeExcluded()}
        let chatListObjectsCount = filteredContacts.count + chats.count
        
        if chatListObjectsCount == chatListObjects.count && chatsCount == chats.count && chatListObjectsCount > 0 {
            chatListObjects = orderChatListObjects(objects: chatListObjects)
            return chatListObjects
        }
        
        chatsCount = chats.count
        
        let chatsWithLastMessages = chats.map{ (chat) -> Chat in
            chat.lastMessage = chat.getLastMessageToShow()
            return chat
        }
        
        var allObject: [ChatListCommonObject] = []
        allObject.append(contentsOf: filteredContacts)
        allObject.append(contentsOf: chatsWithLastMessages)
        
        chatListObjects = orderChatListObjects(objects: allObject)
        return chatListObjects
    }
    
    func orderChatListObjects(objects: [ChatListCommonObject]) -> [ChatListCommonObject] {
        let orderedObjects = objects.sorted(by: {
            let contact1 = $0 as ChatListCommonObject
            let contact2 = $1 as ChatListCommonObject
            
            if contact1.isPending() || contact2.isPending() {
                return $0.isPending() && !$1.isPending()
            }
            
            if let contact1Date = contact1.getOrderDate() {
                if let contact2Date = contact2.getOrderDate() {
                    return contact1Date > contact2Date
                }
                return true
            } else if let _ = contact2.getOrderDate() {
                return false
            }
            
            return contact1.getName().lowercased() < contact2.getName().lowercased()
        })
        return orderedObjects
    }
    
    public func updateProfileImage(userId: Int, profilePicture: String){
        if let contact = UserContact.getContactWith(id: userId) {
            contact.avatarUrl = profilePicture
            contact.saveContact()
        }
    }
    
    public func getObjectsWith(searchString: String) -> [ChatListCommonObject] {
        var allChatListObject = getChatListObjects()
        if searchString != "" {
            allChatListObject =  allChatListObject.filter {
                return $0.getName().lowercased().contains(searchString.lowercased())
            }
        }
        return allChatListObject
    }
    
    public func updateContact(contact: UserContact?, nickname: String? = nil, routeHint: String? = nil, contactKey: String? = nil, pin: String? = nil, callback: @escaping (Bool) -> ()) {
        guard let contact = contact else {
            return
        }
        
        var parameters: [String : AnyObject] = [:]
        
        if let nickname = nickname {
            parameters["alias"] = nickname as AnyObject
        }
        
        if let routeHint = routeHint {
            parameters["route_hint"] = routeHint as AnyObject
        }
        
        if let contactKey = contactKey {
            parameters["contact_key"] = contactKey as AnyObject
        }
        
        API.sharedInstance.updateUser(id: contact.id, params: parameters, callback: { contact in
            DispatchQueue.main.async {
                self.insertContact(contact: contact, pin: pin)
                callback(true)
            }
        }, errorCallback: {
            callback(false)
        })
    }
    
    public func createContact(
        nickname: String,
        pubKey: String,
        routeHint: String? = nil,
        photoUrl: String? = nil,
        pin: String? = nil,
        contactKey: String? = nil,
        callback: @escaping (Bool) -> ()
    ) {
        
        var parameters = [String : AnyObject]()
        parameters["alias"] = nickname as AnyObject
        parameters["public_key"] = pubKey as AnyObject
        parameters["status"] = UserContact.Status.Confirmed.rawValue as AnyObject
        
        if let photoUrl = photoUrl {
            parameters["photo_url"] = photoUrl as AnyObject
        }
        
        if let routeHint = routeHint {
            parameters["route_hint"] = routeHint as AnyObject
        }
        
        if let contactKey = contactKey {
            parameters["contact_key"] = contactKey as AnyObject
        }
        
        API.sharedInstance.createContact(params: parameters, callback: { contact in
            self.insertContact(contact: contact, pin: pin)
            callback(true)
        }, errorCallback: {
            callback(false)
        })
    }
    
    public func exchangeKeys(id: Int) {
        API.sharedInstance.exchangeKeys(id: id, callback: { _ in }, errorCallback: {})
    }
    
    public func reloadSubscriptions(contact: UserContact, callback: @escaping (Bool) -> ()) {
        API.sharedInstance.getSubscriptionsFor(contactId: contact.id, callback: { subscriptions in
            self.insertSubscriptions(subscriptions: subscriptions)
            callback(true)
        }, errorCallback: {
            callback(false)
        })
    }
}
