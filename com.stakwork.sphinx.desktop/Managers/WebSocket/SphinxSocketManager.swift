//
//  SocketManager.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

@objc protocol SocketManagerDelegate: AnyObject {
    @objc optional func didUpdateChatFromMessage(_ chat: Chat)
}

class SphinxSocketManager {
    
    class var sharedInstance : SphinxSocketManager {
        struct Static {
            static let instance = SphinxSocketManager()
        }
        return Static.instance
    }
    
    var incomingMSGTimer : Timer? = nil
    
    weak var delegate: SocketManagerDelegate?
    
    var manager: SocketManager? = nil
    var socket: SocketIOClient? = nil
    let onionConnector = SphinxOnionConnector.sharedInstance
    var preventReconnection = false
    
    var newMessageBubbleHelper = NewMessageBubbleHelper()
    var confirmationIds: [Int] = []
    
    func setDelegate(delegate: SocketManagerDelegate) {
        self.delegate = delegate
    }
    
    func resetSocket() {
        disconnectWebsocket()
        socket = nil
    }
    
    func reconnectSocketToNewIP() {
        resetSocket()
        createAndConnectSocket()
    }
    
    func reconnectSocketOnTor() {
        if isConnected() {
            return
        }
        resetSocket()
        createAndConnectSocket()
    }
    
    func createAndConnectSocket() {
        let (urlString, url) = getSocketUrl()
        
        if onionConnector.usingTor() && !onionConnector.isReady() {
            return
        }

        if socket == nil {
            if let urlString = urlString, let url = url {
                let secure = urlString.starts(with: "wss")
                var socketConfiguration : SocketIOClientConfiguration!
                let headers = UserData.sharedInstance.getAuthenticationHeader()
                
                if onionConnector.usingTor() {
                    socketConfiguration = [
                        .compress,
                        .forcePolling(true),
                        .secure(secure),
                        .extraHeaders(headers)
                    ]
                } else {
                    socketConfiguration = [
                        .compress,
                        .secure(secure),
                        .extraHeaders(headers)
                    ]
                }
                manager = SocketManager(socketURL: url, config: socketConfiguration)
                socket = manager?.defaultSocket
            }

            socket?.on(clientEvent: .connect) {data, ack in
                self.socketDidConnect()
            }

            socket?.on(clientEvent: .disconnect) {data, ack in
                self.socketDidDisconnect()
            }

            socket?.on("message") { dataArray, ack in
                for data in dataArray {
                    if let string = data as? String {
                       self.insertData(dataString: string)
                    }
                }
            }
        }
        socket?.connect()
    }
    
    func getSocketUrl() -> (String?, URL?) {
        let ip = UserData.sharedInstance.getNodeIP()

        if ip == "" {
            return (nil, nil)
        }

        let urlString = API.getWebsocketUrl(route: "\(ip)")
        return (urlString, URL(string: urlString))
    }
    
    func isConnected() -> Bool {
        return (socket?.status ?? .notConnected) == .connected
    }
    
    func isConnecting() -> Bool {
        return (socket?.status ?? .notConnected) == .connecting
    }
    
    func connectWebsocket(forceConnect: Bool = false) {
        let connected = isConnected()
        let connecting = isConnecting()
        let connectedToInternet = ConnectivityHelper.isConnectedToInternet
        
        if forceConnect || (!connected && !connecting && connectedToInternet) {
            if onionConnector.usingTor() {
                resetSocket()
            }
            createAndConnectSocket()
        }
    }
    
    func disconnectWebsocket() {
        preventReconnection = true
        socket?.disconnect()
    }
    
    func socketDidDisconnect() {
        postConnectionStatusChange()
        
        if preventReconnection {
            preventReconnection = false
            return
        }
        connectWebsocket()
    }
    
    func socketDidConnect() {
        postConnectionStatusChange()
        preventReconnection = false
    }
    
    func clearSocket() {
        disconnectWebsocket()
        socket = nil
        manager = nil
    }
    
    func postConnectionStatusChange() {
        NotificationCenter.default.post(name: .onConnectionStatusChanged, object: nil)
    }
}

extension SphinxSocketManager {
    
    func insertData(dataString: String) {
        if let dataFromString = dataString.data(using: .utf8, allowLossyConversion: false) {
            var json : JSON!
            do {
                json = try JSON(data: dataFromString)
            } catch {
                return
            }
            
            if let type = json["type"].string {
                let response = json["response"]
                
                switch(type) {
                case "contact":
                    didReceiveContact(contactJson: response)
                case "invite":
                    didReceiveInvite(inviteJson: response)
                case "group_create":
                    didReceiveGroup(groupJson: response)
                case "group_leave":
                    didLeaveGroup(type: type, json: response)
                case "group_join":
                    didJoinGroup(type: type, json: response)
                case "group_kick", "tribe_delete":
                    tribeDeletedOrkickedFromGroup(type: type, json: response)
                case "member_request":
                    memberRequest(type: type, json: response)
                case "member_approve", "member_reject":
                    memberRequestResponse(type: type, json: response)
                case "invoice_payment":
                    didReceiveInvoicePayment(json: response)
                case "chat_seen":
                    didSeenChat(chatJson: response)
                case "purchase", "purchase_accept", "purchase_deny":
                    didReceivePurchaseMessage(type: type, messageJson: response)
                case "keysend":
                    keysendReceived(json: response)
                default:
                    didReceiveMessage(type: type, messageJson: response)
                }
            }
        }
    }
    
    func didReceiveInvoicePayment(json: JSON) {
        if let string = json["invoice"].string {
            
            let prDecoder = PaymentRequestDecoder()
            prDecoder.decodePaymentRequest(paymentRequest: string)

            if prDecoder.isPaymentRequest() {
                let amount = prDecoder.getAmount() ?? 0

                var message = "\("notification.amount".localized) \(amount) sats"
                
                if let memo = prDecoder.getMemo() {
                    message = message + "\n\("notification.memo".localized) \(memo)"
                }
                
                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    appDelegate.sendNotification(
                        title: "notification.invoice-payment.title".localized,
                        subtitle: nil,
                        text: message
                    )
                }
            }
        }
    }
    
    func togglePaidInvoiceIfNeeded(string: String) {
//        if let vc = delegate as? ChatListViewController, let presentedVC = vc.presentedViewController as? UINavigationController {
//            let viewControllers = presentedVC.viewControllers
//            if viewControllers.count > 1 {
//                if let invoiceDetailsVC = viewControllers[1] as? QRCodeDetailViewController {
//                    invoiceDetailsVC.togglePaidContainer(invoice: string)
//                }
//            }
//        }
    }
    
    func didReceivePurchaseMessage(type: String, messageJson: JSON) {
        let _ = TransactionMessage.insertMessage(
            m: messageJson,
            existingMessage: TransactionMessage.getMessageWith(id: messageJson["id"].intValue)
        )
    }
    
    func didReceiveConfirmationWith(id: Int) {
        confirmationIds.append(id)
        
        if confirmationIds.count > 20 {
            confirmationIds.removeFirst()
        }
    }
    
    func didReceiveMessage(type: String, messageJson: JSON) {
        let isConfirmation = type == "confirmation"
        
        var delay: Double = 0.0
        var existingMessages: TransactionMessage? = nil
        
        if isConfirmation {
            let messageId = messageJson["id"].intValue
            
            if confirmationIds.contains(messageId) {
                return
            }
            
            didReceiveConfirmationWith(id: messageId)
            
            existingMessages = TransactionMessage.getMessageWith(id: messageId)
            
            if existingMessages == nil {
                ///Handles case where confirmation of message is received before the send message endpoint returns.
                ///Adding delay to prevent provisional message not being overwritten (duplicated bubble issue)
                delay =  1.5
            }
        }
        
        if let contactJson = messageJson["contact"].dictionary {
            let _ = UserContact.getOrCreateContact(contact: JSON(contactJson))
        }

        DelayPerformedHelper.performAfterDelay(seconds: delay, completion: {
            if let message = TransactionMessage.insertMessage(
                m: messageJson,
                existingMessage: existingMessages ?? TransactionMessage.getMessageWith(id: messageJson["id"].intValue)
            ).0 {
                message.setPaymentInvoiceAsPaid()
                
                if let chat = message.chat {
                    self.delegate?.didUpdateChatFromMessage?(chat)
                }
                
                self.setSeen(
                    message: message,
                    value: false
                )
                
                self.updateBalanceIfNeeded(type: type)

                let onChat = self.isOnChat(message: message)

                if !isConfirmation {
                    if message.isIncoming() && message.chat?.isPublicGroup() ?? false {
                        self.debounceMessageNotification(message: message, onChat: onChat)
                     } else {
                         self.sendNotification(message: message)
                     }
                }
            }
        })
    }
    
    func debounceMessageNotification(message: TransactionMessage, onChat: Bool) {
        incomingMSGTimer?.invalidate()
        
        incomingMSGTimer = Timer.scheduledTimer(
            timeInterval: 0.3,
            target: self,
            selector: #selector(sendDelayedNotification(timer:)),
            userInfo: ["message": message, "onChat" : onChat],
            repeats: false
        )
    }
    
    @objc func sendDelayedNotification(timer: Timer) {
        if let userInfo = timer.userInfo as? [String: Any] {
            if let message = userInfo["message"] as? TransactionMessage, let _ = userInfo["onChat"] as? Bool {
                sendNotification(message: message)
            }
        }
    }
    
    func updateBalanceIfNeeded(type: String) {
        if type == "payment" || type == "direct_payment" || type == "keysend" || type == "boost" {
            NotificationCenter.default.post(name: .onBalanceDidChange, object: nil)
        }
    }
    
    func didSeenChat(chatJson: JSON) {
        let seen = chatJson["seen"].boolValue

        if let id = chatJson.getJSONId(), let chatToUpdate = Chat.getChatWith(id: id), seen == chatToUpdate.seen {
            return
        }
        
        if let chat = Chat.insertChat(chat: chatJson) {
            chat.setChatMessagesAsSeen(shouldSync: false, shouldSave: false, forceSeen: true)
            
            setAppBadgeCount()
        }
    }
    
    func sendNotification(message: TransactionMessage) {
        setAppBadgeCount()
        
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            
            if message.isOutgoing() || message.shouldAvoidShowingBubble() {
                return
            }
            
            guard let chat = message.chat else {
                return
            }
            
            if chat.isMuted() {
                return
            }
            
            if chat.willNotifyOnlyMentions() && !message.push {
                return
            }
            
            if chat.willNotifyOnlyMentions() {
                if !message.containsMention() {
                    return
                }
            }
            
            appDelegate.sendNotification(message: message)
        }
    }
    
    func didReceiveContact(contactJson: JSON) {
        let _ = UserContact.insertContact(contact: contactJson)
    }
    
    func didReceiveGroup(groupJson: JSON) {
        if let contacts = groupJson["new_contacts"].array {
            for c in contacts {
                let _ = UserContact.insertContact(contact: c)
            }
        }

        let _ = Chat.getOrCreateChat(chat: groupJson["chat"])
    }
    
    func tribeDeletedOrkickedFromGroup(type: String, json: JSON) {
        if let message = json["message"].dictionary {
            didReceiveMessage(type: type, messageJson: JSON(message))
        }
    }
    
    func didLeaveGroup(type: String, json: JSON) {
        didJoinOrLeaveGroup(type: type, json: json)
    }
    
    func didJoinGroup(type: String, json: JSON) {
        didJoinOrLeaveGroup(type: type, json: json)
    }
    
    func didJoinOrLeaveGroup(type: String, json: JSON) {
        if let _ = json["contact"].dictionary, let chatJson = json["chat"].dictionary {
            let _ = Chat.insertChat(chat: JSON(chatJson))
        }

        if let message = json["message"].dictionary {
            didReceiveMessage(type: type, messageJson: JSON(message))
        }
    }
    
    func memberRequest(type: String, json: JSON) {
        if let message = json["message"].dictionary {
            let _ = Chat.insertChat(chat: json["chat"])
            didReceiveMessage(type: type, messageJson: JSON(message))
        }
    }
    
    func memberRequestResponse(type: String, json: JSON) {
        if let message = json["message"].dictionary {
            
            let _ = Chat.insertChat(chat: json["chat"])
            
            didReceiveMessage(type: type, messageJson: JSON(message))
        }
    }

    
    func didReceiveInvite(inviteJson: JSON) {
        let _ = UserInvite.insertInvite(invite: inviteJson)
    }
    
    func shouldUpdateObjectsOnView(contact: UserContact? = nil, chat: Chat? = nil) -> Bool {
        if let _ = delegate as? DashboardViewController {
            return true
        }
        return false
    }
    
    func isOnChat(message: TransactionMessage) -> Bool {
        if delegate == nil || !(delegate is DashboardViewController) {
            return false
        }

        if let del = delegate as? DashboardViewController, let vc = del.newDetailViewController {
            if let chat = vc.chat, let messageChatId = message.chat?.id {
                if chat.id != messageChatId {
                    return false
                }
            }

            if let contact = vc.contact, message.senderId != contact.id {
                return false
            }
        }

        return true
    }
    
    func keysendReceived(json: JSON) {
        let _ = TransactionMessage.insertMessage(
            m: json,
            existingMessage: TransactionMessage.getMessageWith(id: json["id"].intValue)
        )
        let amt = json["amount"].intValue
        
        if amt > 0 {
            updateBalanceIfNeeded(type: "keysend")
        }
        
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.sendNotification(
                title: "notification.keysend.title".localized,
                subtitle: nil,
                text: "\("notification.amount".localized) \(amt) sats"
            )
        }
    }
    
    func setSeen(
        message: TransactionMessage,
        value: Bool
    ) {
        message.seen = value
        message.chat?.seen = value
    }
    
    func setAppBadgeCount() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setBadge(count: TransactionMessage.getReceivedUnseenMessagesCount())
        }
    }
}
