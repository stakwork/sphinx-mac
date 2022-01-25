//
//  UserContactChatListExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import CoreData

extension UserContact : ChatListCommonObject {
    public func getObjectId() -> Int {
        return self.id
    }
    
    public func getOrderDate() -> Date? {
        if let lastMessage = lastMessage {
            return lastMessage.date
        }
        return createdAt
    }
    
    public func getName() -> String {
        return getUserName()
    }
    
    func getUserName(forceNickname: Bool = false) -> String {
        if isOwner && !forceNickname {
            return "name.you".localized
        }
        if let nn = nickname, nn != "" {
            return nn
        }
        return "name.unknown".localized
    }
    
    public func getPhotoUrl() -> String? {
        return avatarUrl
    }
    
    public func getCachedImage() -> NSImage? {
        if let url = getPhotoUrl(), let cachedImage = MediaLoader.getImageFromCachedUrl(url: url) {
            return cachedImage
        }
        return nil
    }
    
    public func getChatContacts() -> [UserContact] {
        return [self]
    }
    
    public func getColor() -> NSColor {
        let key = "\(self.id)-color"
        return NSColor.getColorFor(key: key)
    }
    
    public func deleteColor() {
        let key = "\(self.id)-color"
        NSColor.removeColorFor(key: key)
    }
    
    public func shouldShowSingleImage() -> Bool {
        return true
    }
    
    public func isGroupObject() -> Bool {
        return false
    }
}
