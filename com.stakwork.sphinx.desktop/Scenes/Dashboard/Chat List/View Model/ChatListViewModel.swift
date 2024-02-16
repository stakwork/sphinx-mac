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
    
    public static let kMessagesPerPage: Int = 200
    
    public static var restoreRunning = false
    
    public static func isRestoreRunning() -> Bool {
        return restoreRunning
    }
    
    func loadFriends(
        progressCompletion: ((Bool) -> ())? = nil,
        completion: @escaping (Bool) -> ()
    ) {
        let restoring = self.isRestoring()
        
        ChatListViewModel.restoreRunning = restoring

        restoreContacts(
            page: 1,
            restoring: restoring,
            progressCompletion: progressCompletion,
            completion: completion
        )
    }
    
    func restoreContacts(
        page: Int,
        restoring: Bool,
        progressCompletion: ((Bool) -> ())? = nil,
        completion: @escaping (Bool) -> ()
    ) {
        API.sharedInstance.getLatestContacts(
            page: page,
            date: Date(),
            nextPageCallback: {(contacts, chats, subscriptions, invites) -> () in
                self.saveObjects(
                    contacts: contacts,
                    chats: chats,
                    subscriptions: subscriptions,
                    invites: invites
                )
                
                self.restoreContacts(
                    page: page + 1,
                    restoring: restoring,
                    progressCompletion: progressCompletion,
                    completion: completion
                )
                
                progressCompletion?(restoring)
            },
            callback: {(contacts, chats, subscriptions, invites) -> () in
            
                self.saveObjects(
                    contacts: contacts,
                    chats: chats,
                    subscriptions: subscriptions,
                    invites: invites
                )
                
                CoreDataManager.sharedManager.persistentContainer.viewContext.saveContext()
                    
                self.forceKeychainSync()
                self.authenticateWithMemesServer()
                
                completion(restoring)
            }
        )
    }
    
    func saveObjects(
        contacts: [JSON],
        chats: [JSON],
        subscriptions: [JSON],
        invites: [JSON]
    ) {
        UserContactsHelper.insertObjects(
            contacts: contacts,
            chats: chats,
            subscriptions: subscriptions,
            invites: invites
        )
    }
    
    func forceKeychainSync() {
        UserData.sharedInstance.forcePINSyncOnKeychain()
        UserData.sharedInstance.saveNewNodeOnKeychain()
        EncryptionManager.sharedInstance.saveKeysOnKeychain()
    }
    
    func authenticateWithMemesServer() {
        AttachmentsManager.sharedInstance.runAuthentication()
    }
    
    func isRestoring() -> Bool {
        return API.sharedInstance.lastSeenMessagesDate == nil
    }
    
    var syncMessagesTask: DispatchWorkItem? = nil
    var syncMessagesDate = Date()
    var newMessagesChatIds = [Int]()
    
    func syncMessages(
        chatId: Int? = nil,
        progressCallback: @escaping (Double, Bool) -> (),
        completion: @escaping (Int, Int) -> ()
    ) {
        UserDefaults.Keys.messagesFetchPage.set(
            UserDefaults.Keys.messagesFetchPage.get(defaultValue: 1)
        )
        
        self.newMessagesChatIds = []
        self.syncMessagesDate = Date()
    
        self.getMessagesPaginated(
            prevPageNewMessages: 0,
            chatId: chatId,
            date: self.syncMessagesDate,
            progressCallback: progressCallback,
            completion: { chatNewMessagesCount, newMessagesCount in
                
                UserDefaults.Keys.messagesFetchPage.removeValue()
                
                completion(chatNewMessagesCount, newMessagesCount)
            }
        )
    }
    
    func finishRestoring() {
        SignupHelper.completeSignup()
        UserDefaults.Keys.messagesFetchPage.removeValue()
        API.sharedInstance.lastSeenMessagesDate = syncMessagesDate
    }
    
    func getMessagesPaginated(
        prevPageNewMessages: Int,
        chatId: Int? = nil,
        date: Date,
        retry: Int = 0,
        progressCallback: @escaping (Double, Bool) -> (),
        completion: @escaping (Int, Int) -> ()
    ) {
        
        let page = UserDefaults.Keys.messagesFetchPage.get(defaultValue: 1)

        API.sharedInstance.getMessagesPaginated(
            page: page,
            date: date,
            callback: {(newMessagesTotal, newMessages) -> () in
                
                let restoring = self.isRestoring()
                
                if newMessages.count > 0 {
                    
                    progressCallback(
                        self.getRestoreProgress(
                            currentPage: page,
                            newMessagesTotal: newMessagesTotal,
                            itemsPerPage: ChatListViewModel.kMessagesPerPage
                        ), restoring
                    )
                    
                    self.addMessages(
                        messages: newMessages,
                        chatId: chatId,
                        completion: { (newChatMessagesCount, newMessagesCount) in
                            
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
                if retry < 5 {
                    DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
                        self.getMessagesPaginated(
                            prevPageNewMessages: prevPageNewMessages,
                            chatId: chatId,
                            date: date,
                            retry: retry + 1,
                            progressCallback: progressCallback,
                            completion: completion
                        )
                    })
                }
            })
    }
    
    func getRestoreProgress(
        currentPage: Int,
        newMessagesTotal: Int,
        itemsPerPage: Int
    ) -> Double {
        
        if (newMessagesTotal <= 0) {
            return -1
        }
        
        let pages = (newMessagesTotal <= itemsPerPage) ? 1 : (Double(newMessagesTotal) / Double(itemsPerPage))
        let progress = Double(currentPage) * 100 / pages

        return progress
    }
    
    func getExistingMessagesFor(
        ids: [Int]
    ) -> [Int: TransactionMessage] {
        var messagesMap: [Int: TransactionMessage] = [:]
        
        for existingMessage in TransactionMessage.getMessagesWith(ids: ids) {
            messagesMap[existingMessage.id] = existingMessage
        }
        
        return messagesMap
    }
    
    func addMessages(
        messages: [JSON],
        chatId: Int? = nil,
        completion: @escaping (Int, Int) -> ()
    ) {
        
        let ids: [Int] = messages.map({ $0["id"].intValue })
        let existingMessagesMap = getExistingMessagesFor(ids: ids)
        
        var newChatMessagesCount = 0
        
        for messageDictionary in messages {
            var existingMessage: TransactionMessage? = nil
            
            if let id = messageDictionary["id"].int {
                existingMessage = existingMessagesMap[id]
            }
            
            let (message, isNew) = TransactionMessage.insertMessage(
                m: messageDictionary,
                existingMessage: existingMessage
            )
            
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
