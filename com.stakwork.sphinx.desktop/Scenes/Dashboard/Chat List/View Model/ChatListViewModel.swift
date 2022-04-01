//
//  ChatListViewModel.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

final class ChatListViewModel: NSObject {
    
    private var contactsService: ContactsService!
    
    public static let kMessagesPerPage: Int = 200
    
    init(contactsService: ContactsService) {
        self.contactsService = contactsService
    }
    
    func loadFriends(completion: @escaping () -> ()) {
        if let contactsService = contactsService {
            API.sharedInstance.getLatestContacts(date: Date(), callback: {(contacts, chats, subscriptions, invites) -> () in
                contactsService.insertObjects(contacts: contacts, chats: chats, subscriptions: subscriptions, invites: invites)
                self.forceKeychainSync()
                completion()
            })
        }
    }
    
    func getChatListObjectsCount() -> Int {
        if let contactsService = contactsService {
            return contactsService.chatListObjects.count
        }
        return 0
    }
    
    func updateContactsAndChats() {
        guard let contactsService = contactsService else {
            return
        }
        contactsService.updateContacts()
        contactsService.updateChats()
    }
    
    func forceKeychainSync() {
        UserData.sharedInstance.forcePINSyncOnKeychain()
        UserData.sharedInstance.saveNewNodeOnKeychain()
        EncryptionManager.sharedInstance.saveKeysOnKeychain()
    }
    
    func isRestoring() -> Bool {
        return API.sharedInstance.lastSeenMessagesDate == nil
    }
    
    var syncMessagesTask: DispatchWorkItem? = nil
    var syncMessagesDate = Date()
    var newMessagesChatIds = [Int]()
    
    func syncMessages(
        chatId: Int? = nil,
        progressCallback: @escaping (Int, Bool) -> (),
        completion: @escaping (Int, Int) -> ()
    ) {
        if syncMessagesTask != nil {
            return
        }
        
        let restoring = self.isRestoring()
        
        if !restoring {
            UserDefaults.Keys.messagesFetchPage.removeValue()
        }
        
        syncMessagesTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            self.newMessagesChatIds = []
            self.syncMessagesDate = Date()
        
            self.getMessagesPaginated(
                restoring: restoring,
                prevPageNewMessages: 0,
                chatId: chatId,
                date: self.syncMessagesDate,
                progressCallback: progressCallback,
                completion: { chatNewMessagesCount, newMessagesCount in
                    
                    UserDefaults.Keys.messagesFetchPage.removeValue()
                    
                    self.cancelAndResetSyncMessagesTask()
                    
                    Chat.updateLastMessageForChats(
                        self.newMessagesChatIds
                    )
                    
                    completion(chatNewMessagesCount, newMessagesCount)
                }
            )
        }
        
        syncMessagesTask?.perform()
    }
    
    func finishRestoring() {
        cancelAndResetSyncMessagesTask()
        
        SignupHelper.completeSignup()
        UserDefaults.Keys.messagesFetchPage.removeValue()
        API.sharedInstance.lastSeenMessagesDate = syncMessagesDate
    }
    
    func cancelAndResetSyncMessagesTask() {
        syncMessagesTask?.cancel()
        syncMessagesTask = nil
    }
    
    func getMessagesPaginated(
        restoring: Bool,
        prevPageNewMessages: Int,
        chatId: Int? = nil,
        date: Date,
        progressCallback: @escaping (Int, Bool) -> (),
        completion: @escaping (Int, Int) -> ()
    ) {
        
        let page = UserDefaults.Keys.messagesFetchPage.get(defaultValue: 1)
        
        API.sharedInstance.getMessagesPaginated(
            page: page,
            date: date,
            callback: {(newMessagesTotal, newMessages) -> () in
                
                if self.syncMessagesTask == nil || self.syncMessagesTask?.isCancelled == true {
                    return
                }
                
                progressCallback(
                    self.getRestoreProgress(
                        currentPage: page,
                        newMessagesTotal: newMessagesTotal,
                        itemsPerPage: ChatListViewModel.kMessagesPerPage
                    ), restoring
                )
                
                if newMessages.count > 0 {
                    self.addMessages(
                        messages: newMessages,
                        chatId: chatId,
                        completion: { (newChatMessagesCount, newMessagesCount) in
                            
                            if self.syncMessagesTask == nil || self.syncMessagesTask?.isCancelled == true {
                                return
                            }
                            
                            if newMessages.count < ChatListViewModel.kMessagesPerPage {
                                
                                CoreDataManager.sharedManager.saveContext()
                                
                                if restoring {
                                    SphinxSocketManager.sharedInstance.connectWebsocket()
                                    SignupHelper.completeSignup()
                                }
                                
                                completion(newChatMessagesCount, newMessagesCount)
                                
                            } else {
                                
                                CoreDataManager.sharedManager.saveContext()
                                UserDefaults.Keys.messagesFetchPage.set(page + 1)
                                
                                self.getMessagesPaginated(
                                    restoring: restoring,
                                    prevPageNewMessages: newMessagesCount + prevPageNewMessages,
                                    chatId: chatId,
                                    date: date,
                                    progressCallback: progressCallback,
                                    completion: completion
                                )
                            }
                        })
                } else {
                    completion(0, 0)
                }
            }, errorCallback: {
                DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                    self.getMessagesPaginated(
                        restoring: restoring,
                        prevPageNewMessages: prevPageNewMessages,
                        chatId: chatId,
                        date: date,
                        progressCallback: progressCallback,
                        completion: completion
                    )
                })
                completion(0, 0)
            })
    }
    
    func getRestoreProgress(
        currentPage: Int,
        newMessagesTotal: Int,
        itemsPerPage: Int
    ) -> Int {
        
        if (newMessagesTotal <= 0) {
            return -1
        }
        
        let pages = (newMessagesTotal <= itemsPerPage) ? 1 : (newMessagesTotal / itemsPerPage)
        let progress: Int = currentPage * 100 / pages

        return progress
    }
    
    func addMessages(messages: [JSON], chatId: Int? = nil, completion: @escaping (Int, Int) -> ()) {
        var newChatMessagesCount = 0
        
        for messageDictionary in messages {
            let (message, isNew) = TransactionMessage.insertMessage(m: messageDictionary)
            if let message = message {
                message.setPaymentInvoiceAsPaid()
                
                if isAddedRow(message: message, isNew: isNew, viewChatId: chatId) {
                    newChatMessagesCount = newChatMessagesCount + 1
                }
                
                if let chat = message.chat, !newMessagesChatIds.contains(chat.id) {
                    newMessagesChatIds.append(chat.id)
                }
            }

        }
        completion(newChatMessagesCount, messages.count)
    }
    
    func isAddedRow(message: TransactionMessage, isNew: Bool, viewChatId: Int?) -> Bool {
        if TransactionMessage.typesToExcludeFromChat.contains(message.type) {
            return false
        }
        
        if let messageChatId = message.chat?.id, let viewChatId = viewChatId {
            if (isNew || !message.seen) {
                return messageChatId == viewChatId
            }
        }
        return false
    }
    
    func payInvite(invite: UserInvite, completion: @escaping (UserContact?) -> ()) {
        guard let inviteString = invite.inviteString else {
            completion(nil)
            return
        }
        
        let bubbleHelper = NewMessageBubbleHelper()
        bubbleHelper.showLoadingWheel()
        
        API.sharedInstance.payInvite(inviteString: inviteString, callback: { inviteJson in
            bubbleHelper.hideLoadingWheel()
            
            if let invite = UserInvite.insertInvite(invite: inviteJson) {
                if let contact = invite.contact {
                    invite.setPaymentProcessed()
                    completion(contact)
                    return
                }
            }
            completion(nil)
        }, errorCallback: {
            bubbleHelper.hideLoadingWheel()
            completion(nil)
        })
    }
}
