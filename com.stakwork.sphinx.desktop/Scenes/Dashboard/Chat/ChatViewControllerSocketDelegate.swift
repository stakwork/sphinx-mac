//
//  ChatViewControllerSocketDelegate.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 25/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension ChatViewController {
    func updateViewChat(updatedChat: Chat?) {
        if let updatedChat = updatedChat {
            if let contact = self.contact, let vcChat = contact.getConversation(), updatedChat.id == vcChat.id {
                self.chat = updatedChat
            }
            
            if let vcChat = self.chat, updatedChat.id == vcChat.id {
                self.chat = updatedChat
            }
            chatDataSource?.chat = self.chat
            checkActiveTribe()
        }
    }
    
    func updateViewContact(contact: UserContact) {
        if let vcContact = self.contact, vcContact.id == contact.id {
            self.contact = contact
        }
    }
    
    func didReceiveMessage(message: TransactionMessage) {
        if self.chat == nil {
            updateViewChat(updatedChat: message.chat)
        }
        
        if message.isPayment() {
            reloadMessages(newMessageCount: 1)
            return
        }
        chatDataSource?.addMessageAndReload(message: message)
    }
    
    func didReceiveConfirmation(message: TransactionMessage) {
        chatDataSource?.addMessageAndReload(message: message, confirmation: true)
    }
    
    func didReceivePurchaseUpdate(message: TransactionMessage) {
        let _ = chatDataSource?.reloadAttachmentRow(m: message)
    }
    
    func shouldShowAlert(message: String) {
        
    }
    
    func didUpdateContact(contact: UserContact) {
        if self.contact == nil && self.chat == nil {
            return
        }
        
        updateViewContact(contact: contact)
        updateViewChat(updatedChat: contact.getConversation())
        chatDataSource?.updateContact(contact: contact)
        setChatInfo()
    }
    
    func didUpdateChat(chat: Chat) {
        updateViewChat(updatedChat: chat)
    }
}
