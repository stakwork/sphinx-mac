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
            API.sharedInstance.getContacts(callback: {(contacts, chats, subscriptions) -> () in
                contactsService.insertObjects(contacts: contacts, chats: chats, subscriptions: subscriptions)
                self.forceKeychainSync()
                completion()
            })
            return
        }
        completion()
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
    
    func shouldGetAllMessages(chatId: Int? = nil) -> Bool {
        let lastSeenDate = API.sharedInstance.lastSeenMessagesDate
        let didJustRestore = UserDefaults.Keys.didJustRestore.get(defaultValue: false)
        return (lastSeenDate == nil) || (chatId == nil && TransactionMessage.getAllMesagesCount() == 0 && didJustRestore)
    }
    
    func syncMessages(chatId: Int? = nil, progressCallback: @escaping (String) -> (), completion: @escaping (Int, Int) -> ()) {
        if SignupHelper.isRestoring {
            return
        }
        
        if shouldGetAllMessages(chatId: chatId) {
            progressCallback("fetching.old.messages".localized)
            SignupHelper.isRestoring = true
            getAllMessages(page: 1, date: Date(), completion: completion)
        } else {
            getMessagesPaginated(page: 1, prevPageNewMessages: 0, chatId: chatId, date: Date(), progressCallback: progressCallback, completion: completion)
        }
        UserDefaults.Keys.didJustRestore.set(false)
    }
    
    func getAllMessages(page: Int, date: Date, completion: @escaping (Int, Int) -> ()) {
        API.sharedInstance.getAllMessages(page: page, date: date, callback: { messages in
            self.addMessages(messages: messages, completion: { (_, _) in
                if messages.count < ChatListViewModel.kMessagesPerPage {
                    SphinxSocketManager.sharedInstance.connectWebsocket()
                    SignupHelper.completeSignup()
                    SignupHelper.isRestoring = false
                    completion(1, 1)
                } else {
                    self.getAllMessages(page: page + 1, date: date, completion: completion)
                }
            })
        }, errorCallback: {
            completion(0, 0)
        })
    }
    
    func getMessagesPaginated(page: Int, prevPageNewMessages: Int, chatId: Int? = nil, date: Date, progressCallback: @escaping (String) -> (), completion: @escaping (Int, Int) -> ()) {
        API.sharedInstance.getMessagesPaginated(page: page, date: date, callback: {(newMessages) -> () in
            if newMessages.count > 0 {
                if newMessages.count > 100 {
                    progressCallback("fetching.new.messages".localized)
                }
                
                DelayPerformedHelper.performAfterDelay(seconds: 0.3, completion: {
                    self.addMessages(messages: newMessages, chatId: chatId, completion: { (newChatMessagesCount, newMessagesCount) in
                        if newMessages.count < ChatListViewModel.kMessagesPerPage {
                            completion(newChatMessagesCount, newMessagesCount)
                        } else {
                            self.getMessagesPaginated(page: page + 1, prevPageNewMessages: newMessagesCount + prevPageNewMessages, chatId: chatId, date: date, progressCallback: progressCallback, completion: completion)
                        }
                    })
                })
            } else {
                completion(0, 0)
            }
        }, errorCallback: {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.getMessagesPaginated(page: page, prevPageNewMessages: prevPageNewMessages, chatId: chatId, date: date, progressCallback: progressCallback, completion: completion)
            })
        })
    }
    
    func addMessages(messages: [JSON], chatId: Int? = nil, completion: @escaping (Int, Int) -> ()) {
        var newChatMessagesCount = 0
        var newMessagesCount = 0
        
        for messageDictionary in messages {
            let (message, isNew) = TransactionMessage.insertMessage(m: messageDictionary)
            if let message = message {
                message.setPaymentInvoiceAsPaid()
                
                if isAddedRow(message: message, isNew: isNew, viewChatId: chatId) {
                    newChatMessagesCount = newChatMessagesCount + 1
                } else if isNew {
                    newMessagesCount = newMessagesCount + 1
                }
            }

        }
        completion(newChatMessagesCount, newMessagesCount)
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
