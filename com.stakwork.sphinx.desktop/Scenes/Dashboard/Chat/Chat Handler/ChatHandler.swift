//
//  ChatHandler.swift
//  Sphinx
//
//  Created by Rashid Mustafa on 25/01/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Foundation
class ChatHandler {
    
    static let shared = ChatHandler()
    var replyableMessages: [TransactionMessage] = []
    
    func deleteReplyableMessage(with chat: Chat?) {
        guard chat != nil else { return }
        replyableMessages.removeAll(where: { $0.chat?.id == chat?.id})
    }
    
    func saveReplyableMessages(with message: TransactionMessage,
                               chat: Chat?) {
        if replyableMessages.isEmpty {
            replyableMessages.append(message)
        } else {
            guard let chat = chat else { return }
            if let existingIndex = replyableMessages.firstIndex(where: { $0.chat?.id == chat.id }) {
                replyableMessages.remove(at: existingIndex)
            }
            replyableMessages.append(message)
        }
    }
}
