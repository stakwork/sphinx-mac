//
//  ChatChatListExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import CoreData

extension Chat : ChatListCommonObject {
    public func getContactStatus() -> Int? {
        return UserContact.Status.Confirmed.rawValue
    }
    
    public func getInviteStatus() -> Int? {
        return UserInvite.Status.Complete.rawValue
    }
    
    public func getObjectId() -> String {
        return "chat-\(self.id)"
    }
    
    public func isSeen(ownerId: Int) -> Bool {
        if self.lastMessage?.isOutgoing(ownerId: ownerId) ?? true {
            return true
        }
        
        if self.lastMessage?.isSeen(ownerId: ownerId) ?? true {
            return true
        }
        
        return self.seen
    }
    
    public func getChat() -> Chat? {
        self
    }
    
    public func getInvite() -> UserInvite? {
        return nil
    }
    
    public func getObjectId() -> Int {
        return self.id
    }
    
    public func getOrderDate() -> Date? {
        var date: Date? = nil
        
        if let lastMessage = lastMessage {
            date = lastMessage.date
        }
        
        if let webAppLastDate = webAppLastDate,
           let savedDate = date, webAppLastDate > savedDate {
            
            date = webAppLastDate
        }
        
        return date ?? createdAt ?? Date()
    }
    
    func getConversationContact() -> UserContact? {
        if isGroup() {
            return nil
        }
        
        if conversationContact == nil {
            let contacts = getContacts(includeOwner: false)
            conversationContact = contacts.first
        }
        
        return conversationContact
    }
    
    public func getContact() -> UserContact? {
        if self.type == Chat.ChatType.conversation.rawValue {
            return getConversationContact()
        }
        return nil
    }
    
    public func getName() -> String {
        if isConversation() {
            return getConversationContact()?.getName() ?? ""
        }
        return name ?? "unknown.group".localized
    }
    
    public func isPending() -> Bool {
        return false
    }
    
    public func isConfirmed() -> Bool {
        return true
    }
    
    public func hasEncryptionKey() -> Bool {
        return true
    }
    
    public func subscribedToContact() -> Bool {
        return false
    }
    
    public func isMuted() -> Bool {
        return self.notify == NotificationLevel.MuteChat.rawValue
    }
    
    public func willNotifyAll() -> Bool {
        return self.notify == NotificationLevel.SeeAll.rawValue
    }
    
    public func willNotifyOnlyMentions() -> Bool {
        return self.notify == NotificationLevel.OnlyMentions.rawValue
    }
    
    public func isPublicGroup() -> Bool {
        return type == Chat.ChatType.publicGroup.rawValue
    }
    
    public func isConversation() -> Bool {
        return type == Chat.ChatType.conversation.rawValue
    }
    
    public func shouldShowSingleImage() -> Bool {
        if isPublicGroup() || isConversation() {
            return true
        }
        if let url = photoUrl, url != "" {
            return true
        }
        return getChatContacts().count == 1
    }
    
    public func getPhotoUrl() -> String? {
        if isConversation() {
            return getConversationContact()?.getPhotoUrl() ?? ""
        }
        return photoUrl
    }
    
    public func getCachedImage() -> NSImage? {
        if let url = getPhotoUrl(), let cachedImage = MediaLoader.getImageFromCachedUrl(url: url) {
            return cachedImage
        }
        return nil
    }
    
    public func getChatContacts() -> [UserContact] {
        return self.getContacts(ownerAtEnd: true)
    }
    
    public func getConversation() -> Chat? {
        return self
    }
    
    public func isGroupObject() -> Bool {
        return true
    }
    
    public func getColor() -> NSColor {
        if let contact = self.getContact() {
            return contact.getColor()
        }
        let key = "chat-\(self.id)-color"
        return NSColor.getColorFor(key: key)
    }
    
    public func deleteColor() {
        let key = "chat-\(self.id)-color"
        NSColor.removeColorFor(key: key)
    }
}

