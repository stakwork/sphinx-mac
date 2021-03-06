//
//  TransactionMessageQueriesExtension.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import CoreData

extension TransactionMessage {    
    static func getAll() -> [TransactionMessage] {
        let messages:[TransactionMessage] = CoreDataManager.sharedManager.getAllOfType(entityName: "TransactionMessage")
        return messages
    }
    
    static func getAllMesagesCount() -> Int {
        let messagesCount:Int = CoreDataManager.sharedManager.getObjectsCountOfTypeWith(entityName: "TransactionMessage")
        return messagesCount
    }
    
    static func getMessageWith(id: Int) -> TransactionMessage? {
        let message: TransactionMessage? = CoreDataManager.sharedManager.getObjectOfTypeWith(id: id, entityName: "TransactionMessage")
        return message
    }
    
    static func getMessageWith(uuid: String) -> TransactionMessage? {
        let predicate = NSPredicate(format: "uuid == %@", uuid)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let message: TransactionMessage? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return message
    }
    
    static func getAllMessagesFor(chat: Chat,
                                  limit: Int? = nil,
                                  messagesIdsToExclude: [Int] = [],
                                  lastMessage: TransactionMessage? = nil) -> [TransactionMessage] {
        
        var predicate : NSPredicate!
        if messagesIdsToExclude.count > 0 {
            if let m = lastMessage {
                predicate = NSPredicate(format: "chat == %@ AND (NOT id IN %@) AND (date <= %@) AND NOT (type IN %@)", chat, messagesIdsToExclude, m.date as NSDate, typesToExcludeFromChat)
            } else {
                predicate = NSPredicate(format: "chat == %@ AND (NOT id IN %@) AND NOT (type IN %@)", chat, messagesIdsToExclude, typesToExcludeFromChat)
            }
        } else {
            if let m = lastMessage {
                predicate = NSPredicate(format: "chat == %@ AND (date <= %@) AND NOT (type IN %@)", chat, m.date as NSDate, typesToExcludeFromChat)
            } else {
                predicate = NSPredicate(format: "chat == %@ AND NOT (type IN %@)", chat, typesToExcludeFromChat)
            }
        }
        let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false), NSSortDescriptor(key: "id", ascending: false)]
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage", fetchLimit: limit)
        return messages.reversed()
    }
    
    static func getAllMessagesCountFor(chat: Chat, lastMessageId: Int? = nil) -> Int {
        return CoreDataManager.sharedManager.getObjectsCountOfTypeWith(predicate: NSPredicate(format: "chat == %@ AND NOT (type IN %@)", chat, typesToExcludeFromChat), entityName: "TransactionMessage")
    }
    
    static func getNewMessagesCountFor(chat: Chat, lastMessageId: Int) -> Int {
        return CoreDataManager.sharedManager.getObjectsCountOfTypeWith(predicate: NSPredicate(format: "chat == %@ AND id > %d", chat, lastMessageId), entityName: "TransactionMessage")
    }
    
    static func getInvoiceWith(paymentHash: String) -> TransactionMessage? {
        let predicate = NSPredicate(format: "type == %d AND paymentHash == %@", TransactionMessageType.invoice.rawValue, paymentHash)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let invoice: TransactionMessage? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return invoice
    }
    
    static func getInvoiceWith(paymentRequestString: String) -> TransactionMessage? {
        let predicate = NSPredicate(format: "type == %d AND invoice == %@", TransactionMessageType.invoice.rawValue, paymentRequestString)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let invoice: TransactionMessage? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return invoice
    }
    
    static func getMessagesFor(userId: Int, contactId: Int) -> [TransactionMessage] {
        let predicate = NSPredicate(format: "((senderId == %d AND receiverId == %d) OR (senderId == %d AND receiverId == %d)) AND id >= 0 AND NOT (type IN %@)", contactId, userId, userId, contactId, typesToExcludeFromChat)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return messages
    }
    
        static func getLastGroupRequestFor(contactId: Int, in chat: Chat) -> TransactionMessage? {
        let predicate = NSPredicate(format: "senderId == %d AND chat == %@ AND type == %d", contactId, chat, TransactionMessageType.memberRequest.rawValue)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage", fetchLimit: 1)
        
        return messages.first
    }
    
    static func getReceivedUnseenMessagesCount() -> Int {
        let userId = UserData.sharedInstance.getUserId()
        let predicate = NSPredicate(format: "senderId != %d AND seen == %@ AND chat != null AND id >= 0 AND chat.seen == %@ AND chat.muted == %@", userId, NSNumber(booleanLiteral: false), NSNumber(booleanLiteral: false), NSNumber(booleanLiteral: false))
        let messagesCount = CoreDataManager.sharedManager.getObjectsCountOfTypeWith(predicate: predicate, entityName: "TransactionMessage")
        return messagesCount
    }
    
    static func getProvisionalMessageId() -> Int {
        let userId = UserData.sharedInstance.getUserId()
        let messageType = TransactionMessageType.message.rawValue
        let attachmentType = TransactionMessageType.attachment.rawValue
        let predicate = NSPredicate(format: "(senderId == %d) AND (type == %d || type == %d) AND id < 0", userId, messageType, attachmentType)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage", fetchLimit: 1)
        
        if messages.count > 0 {
            return messages[0].id - 1
        }
        
        return -1
    }
    
    static func getProvisionalMessageFor(messageContent: String, type: TransactionMessageType, chat: Chat) -> TransactionMessage? {
        let userId = UserData.sharedInstance.getUserId()
        let messageType = type.rawValue
        let pendingStatus = TransactionMessageStatus.pending.rawValue
        var predicate : NSPredicate!
        if (chat.messages?.count ?? 0) > 0 {
            predicate = NSPredicate(format: "(senderId == %d) AND (messageContent == %@) AND (type == %d) AND (status == %d) AND (chat == %@) AND id < 0", userId, messageContent, messageType, pendingStatus, chat)
        } else {
            predicate = NSPredicate(format: "(senderId == %d) AND (messageContent == %@) AND (type == %d) AND (status == %d) AND (chat == nil) AND id < 0", userId, messageContent, messageType, pendingStatus)
        }
        let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage", fetchLimit: 1)
        
        if messages.count > 0 {
            return messages[0]
        }
        return nil
    }
    
    static func getLastProvisionalImageMessage(chat: Chat) -> TransactionMessage? {
        let userId = UserData.sharedInstance.getUserId()
        let attachmentType = TransactionMessageType.attachment.rawValue
        let pendingStatus = TransactionMessageStatus.pending.rawValue
        var predicate : NSPredicate!
        if (chat.messages?.count ?? 0) > 0 {
            predicate = NSPredicate(format: "(senderId == %d) AND (type == %d) AND (status == %d) AND (chat == %@) AND id < 0", userId, attachmentType, pendingStatus, chat)
        } else {
            predicate = NSPredicate(format: "(senderId == %d) AND (type == %d) AND (status == %d) AND (chat == nil) AND id < 0", userId, attachmentType, pendingStatus, chat)
        }
        let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage", fetchLimit: 1)
        
        if messages.count > 0 {
            return messages[0]
        }
        return nil
    }
    
    static func getRecentGiphyMessages() -> [TransactionMessage] {
        let userId = UserData.sharedInstance.getUserId()
        let messageType = TransactionMessageType.message.rawValue
        let predicate = NSPredicate(format: "(senderId == %d) AND (type == %d) AND (messageContent BEGINSWITH[c] %@)", userId, messageType, "giphy::")
        let sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let messages: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage", fetchLimit: 50)

        return messages
    }
    
    static func getPaymentsFor(feedId: Int) -> [TransactionMessage] {
        let feedIDString1 = "{\"feedID\":\"\(feedId)"
        let feedIDString2 = "{\"feedID\":\(feedId)"
        let predicate = NSPredicate(format: "chat == nil && (messageContent BEGINSWITH[c] %@ OR messageContent BEGINSWITH[c] %@)", feedIDString1, feedIDString2)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let payments: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return payments
    }
    
    static func getLiveMessagesFor(chat: Chat, episodeId: Int) -> [TransactionMessage] {
        let episodeString = "\"itemID\":\(episodeId)"
        let episodeString2 = "\"itemID\" : \(episodeId)"
        let predicate = NSPredicate(format: "chat == %@ && ((type == %d && (messageContent BEGINSWITH[c] %@ OR messageContent BEGINSWITH[c] %@)) || (type == %d && replyUUID == nil)) && (messageContent CONTAINS[c] %@ || messageContent CONTAINS[c] %@)", chat, TransactionMessageType.message.rawValue, PodcastPlayerHelper.kClipPrefix, PodcastPlayerHelper.kBoostPrefix, TransactionMessageType.boost.rawValue, episodeString, episodeString2)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let boostAndClips: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return boostAndClips
    }
    
    static func getReactionsOn(chat: Chat, for messages: [String]) -> [TransactionMessage] {
        let boostType = TransactionMessageType.boost.rawValue
        let predicate = NSPredicate(format: "chat == %@ AND type == %d AND replyUUID != nil AND (replyUUID IN %@)", chat, boostType, messages)
        let sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        let reactions: [TransactionMessage] = CoreDataManager.sharedManager.getObjectsOfTypeWith(predicate: predicate, sortDescriptors: sortDescriptors, entityName: "TransactionMessage")
        
        return reactions
    }
}
