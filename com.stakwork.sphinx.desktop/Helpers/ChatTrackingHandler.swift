//
//  ChatTrackingHandler.swift
//  Sphinx
//
//  Created by Rashid Mustafa on 25/01/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Foundation

class ChatTrackingHandler {
    
    class var shared : ChatTrackingHandler {
        struct Static {
            static let instance = ChatTrackingHandler()
        }
        return Static.instance
    }
    
    var replyableMessages: [Int: Int] = [:]
    var ongoingMessages : [String: String] = [:]
    
    func deleteReplyableMessage(with chatId: Int?) {
        guard let chatId = chatId else { return }
        
        replyableMessages.removeValue(forKey: chatId)
    }
    
    func saveReplyableMessage(
        with messageId: Int,
        chatId: Int?
    ) {
        guard let chatId = chatId else { return }
        
        replyableMessages[chatId] = messageId
    }
    
    func getReplyableMessageFor(chatId: Int?) -> TransactionMessage? {
        guard let chatId = chatId else { return nil }
        
        if let messageId = replyableMessages[chatId], let message = TransactionMessage.getMessageWith(id: messageId) {
            return message
        }
        
        return nil
    }
    
    func deleteOngoingMessage(
        with chatId: Int?,
        threadUUID: String?
    ) {
        guard let key = getComposedKeyFor(chatId: chatId, threadUUID: threadUUID) else { return }
        
        ongoingMessages.removeValue(forKey: key)
    }
    
    func saveOngoingMessage(
        with message: String,
        chatId: Int?,
        threadUUID: String?
    ) {
        guard let key = getComposedKeyFor(chatId: chatId, threadUUID: threadUUID) else { return }
        
        ongoingMessages[key] = message
    }
    
    func getOngoingMessageFor(
        chatId: Int?,
        threadUUID: String?
    ) -> String? {
        guard let key = getComposedKeyFor(chatId: chatId, threadUUID: threadUUID) else { return nil }
        
        if let message = ongoingMessages[key] {
            return message
        }
        
        return nil
    }
    
    func getComposedKeyFor(
        chatId: Int?,
        threadUUID: String?
    ) -> String? {
        guard let chatId = chatId else { return nil }
        
        var key = "\(chatId)"
        
        if let threadUUID = threadUUID {
            key = "\(key)-\(threadUUID)"
        }
        
        return key
    }
}
