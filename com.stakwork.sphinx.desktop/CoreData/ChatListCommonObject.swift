//
//  ChatListCommonObject.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

public protocol ChatListCommonObject: AnyObject {
    func isPending() -> Bool
    func isConfirmed() -> Bool
    func isGroupObject() -> Bool
    
    func getObjectId() -> Int
    func getOrderDate() -> Date?
    func getName() -> String
    func getColor() -> NSColor
    func getPhotoUrl() -> String?
    
    func getChatContacts() -> [UserContact]
    func shouldShowSingleImage() -> Bool
    
    func hasEncryptionKey() -> Bool
    func subscribedToContact() -> Bool
    
    func getConversation() -> Chat?
    func updateLastMessage()
    
    var lastMessage : TransactionMessage? { get set }
    var objectPicture : NSImage? { get set }
}
