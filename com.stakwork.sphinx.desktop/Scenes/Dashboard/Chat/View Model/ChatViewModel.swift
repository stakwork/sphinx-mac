//
//  ChatViewModel.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 15/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

final class ChatViewModel: NSObject {
    
    func toggleVolumeOn(
        chat: Chat,
        completion: @escaping (Chat?) -> ()
    ) {
        let currentMode = chat.isMuted()
        
        API.sharedInstance.toggleChatSound(
            chatId: chat.id,
            muted: !currentMode,
            callback: { chatJson in
                if let updatedChat = Chat.insertChat(chat: chatJson) {
                    completion(updatedChat)
                }
            },
            errorCallback: {
                completion(nil)
            }
        )
    }
    
    func shouldDeleteMessage(message: TransactionMessage, completion: @escaping (Bool, TransactionMessage?) -> ()) {
        API.sharedInstance.deleteMessage(messageId: message.id, callback: { (success, m) in
            let updateMessage = TransactionMessage.insertMessage(m: m).0
            completion(success, updateMessage)
        })
    }
}
