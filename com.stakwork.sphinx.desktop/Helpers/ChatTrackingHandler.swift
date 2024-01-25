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
    
    var replyableMessages: [Int: TransactionMessage] = [:]
    var ongoingMessages : [Int: String] = [:]
    
    func deleteReplyableMessage(with chatId: Int?) {
        guard let chatId = chatId else { return }
        
        replyableMessages.removeValue(forKey: chatId)
    }
    
    func saveReplyableMessage(
        with message: TransactionMessage,
        chatId: Int?
    ) {
        guard let chatId = chatId else { return }
        
        replyableMessages[chatId] = message
    }
    
    func getReplyableMessageFor(chatId: Int?) -> TransactionMessage? {
        guard let chatId = chatId else { return nil }
        
        if let message = replyableMessages[chatId] {
            return message
        }
        
        return nil
    }
    
    func deleteOngoingMessage(with chatId: Int?) {
        guard let chatId = chatId else { return }
        
        ongoingMessages.removeValue(forKey: chatId)
    }
    
    func saveOngoingMessage(
        with message: String,
        chatId: Int?
    ) {
        guard let chatId = chatId else { return }
        
        ongoingMessages[chatId] = message
    }
    
    func getOngoingMessageFor(chatId: Int?) -> String? {
        guard let chatId = chatId else { return nil }
        
        if let message = ongoingMessages[chatId] {
            return message
        }
        
        return nil
    }
}
