//
//  ChatListSocketDelegateExtension.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 15/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension ChatListViewController {
    func didReceiveMessage(message: TransactionMessage) {
        shouldReloadChatList()
    }
    
    func didReceiveConfirmation(message: TransactionMessage) {
        shouldReloadChatList()
    }
    
    func didReceivePurchaseUpdate(message: TransactionMessage) {
        shouldReloadChatList()
    }
    
    func shouldReloadChatList() {
        updateContactsAndReload()
    }
    
    func shouldShowAlert(message: String) {
        AlertHelper.showAlert(title: "Hey!", message: message)
    }
    
    func didUpdateContact(contact: UserContact) {
//        chatListDataSource?.updateContactAndReload(object: contact)
    }
    
    func didUpdateChat(chat: Chat) {
//        chatListDataSource?.updateChatAndReload(object: chat)
    }
    
    func didReceiveOrUpdateGroup() {
        loadFriendAndReload()
    }
}
