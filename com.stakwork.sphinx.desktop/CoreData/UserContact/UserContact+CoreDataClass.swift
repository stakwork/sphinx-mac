//
//  UserContact+CoreDataClass.swift
//  
//
//  Created by Tomas Timinskas on 11/05/2020.
//
//

import Foundation
import CoreData
import SwiftyJSON

@objc(UserContact)
public class UserContact: NSManagedObject {
    
    enum Status: Int {
        case Pending
        case Confirmed
    }
    
    public var lastMessage : TransactionMessage? = nil
    public var objectPicture : NSImage? = nil
    
    public static func getContactInstance(id: Int, managedContext: NSManagedObjectContext) -> UserContact {
        if let c = UserContact.getContactWith(id: id) {
            return c
        } else {
            return UserContact(context: managedContext) as UserContact
        }
    }
    
    public static func insertContact(contact: JSON, referenceDate: Date? = nil) -> (UserContact?, Int?) {
        let id: Int? = contact.getJSONId()
        
        if let id = id {
            let publicKey = contact["public_key"].string ?? ""
            let nickname = contact["alias"].string
            let nodeAlias = contact["node_alias"].string
            let avatarUrl = contact["photo_url"].string
            let isOwner = contact["is_owner"].boolValue
            let fromGroup = contact["from_group"].boolValue
            let status = contact["status"].intValue
            let contactKey = contact["contact_key"].string
            let privatePhoto = contact["private_photo"].boolValue
            let tipAmount = contact["tip_amount"].int
            let routeHint = contact["route_hint"].string
            let updatedAtDate = Date.getDateFromString(dateString: contact["updated_at"].stringValue)
            let date = Date.getDateFromString(dateString: contact["created_at"].stringValue) ?? Date()
            
            if let referenceDate = referenceDate, let updatedAtDate = updatedAtDate, updatedAtDate < referenceDate {
                return (nil, id)
            }
            
            var inviteString: String?
            var welcomeMessage: String?
            var inviteStatus: Int = 0
            var invitePrice:NSDecimalNumber? = nil
            
            if let invite = contact["invite"].dictionary {
                if let inviteS = invite["invite_string"]?.string {
                    inviteString = inviteS
                }
                
                if let welcomeM = invite["welcome_message"]?.string {
                    welcomeMessage = welcomeM
                }
                
                if let inviteS = invite["status"]?.intValue {
                    inviteStatus = inviteS
                }
                
                if let p = invite["price"]?.double, abs(p) > 0 {
                    invitePrice = NSDecimalNumber(value: p)
                }
            }
            
            let contact = UserContact.createObject(id: id, publicKey: publicKey, nodeAlias: nodeAlias, nickname: nickname, avatarUrl: avatarUrl, isOwner: isOwner, fromGroup: fromGroup, status: status, contactKey: contactKey, privatePhoto: privatePhoto, tipAmount: tipAmount, routeHint: routeHint, inviteString: inviteString, welcomeMessage: welcomeMessage, inviteStatus: inviteStatus, invitePrice: invitePrice, date: date)
            
            return (contact, contact?.id)
        }
        
        return (nil, nil)
    }
    
    public static func createObject(id: Int,
                                    publicKey: String,
                                    nodeAlias: String?,
                                    nickname: String?,
                                    avatarUrl: String?,
                                    isOwner: Bool,
                                    fromGroup: Bool,
                                    status: Int,
                                    contactKey: String?,
                                    privatePhoto: Bool,
                                    tipAmount: Int?,
                                    routeHint: String?,
                                    inviteString: String?,
                                    welcomeMessage: String?,
                                    inviteStatus: Int,
                                    invitePrice: NSDecimalNumber? = nil, date: Date) -> UserContact? {
        
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        var invite : UserInvite? = nil
        
        if let inviteString = inviteString {
            invite = UserInvite.getInviteInstance(inviteString: inviteString, managedContext: managedContext)
            invite?.inviteString = inviteString
            invite?.welcomeMessage = welcomeMessage
            invite?.status = inviteStatus
            invite?.price = invitePrice
        }

        let contact = getContactInstance(id: id, managedContext: managedContext)
        contact.id = id
        contact.publicKey = publicKey
        contact.nodeAlias = nodeAlias
        contact.nickname = nickname
        contact.avatarUrl = avatarUrl
        contact.isOwner = isOwner
        contact.fromGroup = fromGroup
        contact.status = status
        contact.contactKey = contactKey
        contact.routeHint = routeHint
        contact.invite = invite
        contact.createdAt = date
        contact.privatePhoto = privatePhoto
        
        if let tipAmount = tipAmount, isOwner {
            contact.tipAmount = tipAmount
            UserDefaults.Keys.tipAmount.set(tipAmount)
        }

        managedContext.mergePolicy = NSMergePolicy.overwrite
        
        do {
            try managedContext.save()
            return contact
        } catch {
            return nil
        }
    }

    public static func getAll() -> [UserContact] {
        let sortDescriptors = [NSSortDescriptor(key: "status", ascending: true), NSSortDescriptor(key: "nickname", ascending: true)]
        var predicate: NSPredicate! = nil
        
        if GroupsPinManager.sharedInstance.isStandardPIN {
            predicate = NSPredicate(format: "pin == null")
        } else {
            let currentPin = GroupsPinManager.sharedInstance.currentPin
            predicate = NSPredicate(format: "pin = %@", currentPin)
        }
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact")
        return contacts
    }
    
    public static func getAllExcluding(ids: [Int]) -> [UserContact] {
        var predicate: NSPredicate! = nil
        
        if GroupsPinManager.sharedInstance.isStandardPIN {
            predicate = NSPredicate(format: "NOT (id IN %@) AND pin == null", ids)
        } else {
            let currentPin = GroupsPinManager.sharedInstance.currentPin
            predicate = NSPredicate(format: "NOT (id IN %@) AND pin = %@", ids, currentPin)
        }
        
        let sortDescriptors = [NSSortDescriptor(key: "status", ascending: true), NSSortDescriptor(key: "nickname", ascending: true)]
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact")
        return contacts
    }
    
    public static func getPrivateContacts() -> [UserContact] {
        let predicate = NSPredicate(format: "pin != null")
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "UserContact")
        return contacts
    }
    
    public static func getPendingContacts() -> [UserContact] {
        let predicate = NSPredicate(format: "status == %d", UserContact.Status.Pending.rawValue)
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "UserContact")
        return contacts
    }
    
    public static func deleteAll() {
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        let contacts = UserContact.getAll()
        for contact in contacts {
            managedContext.delete(contact)
        }
        CoreDataManager.sharedManager.saveContext()
    }
    
    public static func getOrCreateContact(contact: JSON) -> (UserContact?, Bool) {
        let contactId = contact["id"].intValue
        if contact["deleted"].boolValue { return (nil, false) }
        
        if let c = getContactWith(id: contactId) {
            let updated = c.updateFromGroup(contact: contact)
            return (c, updated)
        }
        return (UserContact.insertContact(contact: contact).0, false)
    }
    
    func updateFromGroup(contact: JSON) -> Bool {
        if self.fromGroup != contact["from_group"].boolValue {
            self.fromGroup = contact["from_group"].boolValue
            self.saveContact()
            return true
        }
        return false
    }
    
    public static func getContactsWith(ids: [Int], includeOwner: Bool, ownerAtEnd: Bool) -> [UserContact] {
        var predicate: NSPredicate! = nil
        if includeOwner {
            predicate = NSPredicate(format: "id IN %@", ids)
        } else {
            predicate = NSPredicate(format: "id IN %@ AND isOwner == %@", ids, NSNumber(value: false))
        }
        let sortDescriptors = ownerAtEnd ? [NSSortDescriptor(key: "isOwner", ascending: false), NSSortDescriptor(key: "id", ascending: false)] : [NSSortDescriptor(key: "id", ascending: false)]
        let contacts: [UserContact] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact")
        return contacts
    }
    
    public static func getContactWith(id: Int) -> UserContact? {
        let predicate = NSPredicate(format: "id == %d", id)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let contact:UserContact? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact")
        return contact
    }
    
    public static func getContactWith(pubkey: String) -> UserContact? {
        let predicate = NSPredicate(format: "publicKey == %@ AND status == %d", pubkey, UserContact.Status.Confirmed.rawValue)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let contact:UserContact? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact")
        return contact
    }
    
    public static func getOwner() -> UserContact? {
        let predicate = NSPredicate(format: "isOwner == %@", NSNumber(value: true))
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let contact:UserContact? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "UserContact")
        return contact
    }
    
    func getAddress() -> String? {
        if let address = self.publicKey, !address.isEmpty {
            let routeHint = (self.routeHint ?? "").isEmpty ? "" : ":\((self.routeHint ?? ""))"
            return "\(address)\(routeHint)"
        }
        return nil
    }
    
    public func getConversation() -> Chat? {
        let userId = UserData.sharedInstance.getUserId()
        let predicate = NSPredicate(format: "(contactIds == %@ OR contactIds == %@) AND type = %d", [userId, self.id], [self.id, userId], Chat.ChatType.conversation.rawValue)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let chat:Chat? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "Chat")
        return chat
    }
    
    public func getConversation(chats: [Chat]) -> Chat? {
        for chat in chats {
            if chat.getContactIdsArray().contains(self.id) {
                return chat
            }
        }
        return nil
    }

    
    public func getCurrentSubscription() -> Subscription? {
        if let subsciptionsSet = self.subscriptions, let subscriptions = Array<Any>(subsciptionsSet) as? [Subscription] {
            return subscriptions.filter { !$0.ended }.first
        }
        return nil
    }
    
    public func updateLastMessage() {
        if let chat = self.getConversation() {
            self.lastMessage = chat.getLastMessageToShow()
        }
    }
    
    public func subscribedToContact() -> Bool {
        return getCurrentSubscription() != nil
    }
    
    public func hasEncryptionKey() -> Bool {
        if let contactK = self.contactKey, let _ = EncryptionManager.sharedInstance.getPublicKeyFromBase64String(base64String: contactK) {
            return true
        }
        return false
    }
    
    public func isConfirmed() -> Bool {
        return self.status == UserContact.Status.Confirmed.rawValue
    }
    
    public func isPending() -> Bool {
        return self.status == UserContact.Status.Pending.rawValue
    }
    
    public func shouldBeExcluded() -> Bool {
        if fromGroup { return true }
        if let invite = self.invite {
            return self.status != UserContact.Status.Confirmed.rawValue && invite.status == UserInvite.Status.Expired.rawValue
        }
        return false
    }
    
    public func getQRCodeString() -> String? {
        if let publicKey = self.publicKey {
            return publicKey
        }
        return nil
    }
    
    public func saveContact() {
        CoreDataManager.sharedManager.saveContext()
    }
}
