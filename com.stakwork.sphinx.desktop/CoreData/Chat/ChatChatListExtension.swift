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
    public func getObjectId() -> Int {
        return self.id
    }
    
    public func getOrderDate() -> Date? {
        var date: Date? = createdAt
        
        if let lastMessage = lastMessage,
           let lastMessageDate = lastMessage.date {
            
            date = lastMessageDate
        }
        
        if let webAppLastDate = webAppLastDate,
           let savedDate = date, webAppLastDate > savedDate {
            
            date = webAppLastDate
        }
        
        return date
    }
    
    func getConversationContact() -> UserContact? {
        if conversationContact == nil {
            conversationContact = getContact()
        }
        return conversationContact
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

