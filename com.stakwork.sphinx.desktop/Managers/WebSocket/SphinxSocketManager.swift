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
    @objc optional func didReceiveMessage(message: TransactionMessage, onChat: Bool)
    @objc optional func didReceivePurchaseUpdate(message: TransactionMessage)
    @objc optional func didReceiveConfirmation(message: TransactionMessage)
    @objc optional func didUpdateContact(contact: UserContact)
    @objc optional func didUpdateChat(chat: Chat)
    @objc optional func didReceiveOrUpdateGroup()
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
//        if let string = json["invoice"].string {
//            let prDecoder = PaymentRequestDecoder()
//            prDecoder.decodePaymentRequest(paymentRequest: string)
//
//            if prDecoder.isPaymentRequest() {
//                let amount = prDecoder.getAmount() ?? 0
//
//                var message = "Amount: \(amount)"
//                if let memo = prDecoder.getMemo() {
//                    message = message + "\nMemo: \(memo)"
//                }
//                newMessageBubbleHelper.showMessageView(title: "Invoice Paid", text: message)
//                togglePaidInvoiceIfNeeded(string: string)
//            }
//        }
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
        if let message = TransactionMessage.insertMessage(m: messageJson).0 {
            markAsSeenIfNeeded(message: message)
            delegate?.didReceivePurchaseUpdate?(message: message)
        }
    }
    
    func didReceiveMessage(type: String, messageJson: JSON) {
        let isConfirmation = type == "confirmation"
        let incoming = messageJson["sender"].intValue != UserData.sharedInstance.getUserId()
        let messageId = messageJson["id"].intValue
        let deleted = messageJson["status"].intValue == TransactionMessage.TransactionMessageStatus.deleted.rawValue
        let existingMessage = TransactionMessage.getMessageWith(id: messageId)
        
        if incoming && existingMessage != nil && !deleted {
            return
        }
        
        if isConfirmation && (existingMessage?.isConfirmedAsReceived() ?? false) {
            return
        }

        if let message = TransactionMessage.insertMessage(m: messageJson, existingMessage: existingMessage).0 {
            message.setPaymentInvoiceAsPaid()
            markAsSeenIfNeeded(message: message)
            
            updateBalanceIfNeeded(type: type)

            let onChat = isOnChat(message: message)

            if isConfirmation {
                delegate?.didReceiveConfirmation?(message: message)
            } else {
                if message.isIncoming() && message.chat?.isPublicGroup() ?? false {
                    debounceMessageNotification(message: message, onChat: onChat)
                } else {
                    sendNotification(message: message)
                    delegate?.didReceiveMessage?(message: message, onChat: onChat)
                }
            }
        }
    }
    
    func debounceMessageNotification(message: TransactionMessage, onChat: Bool) {
        incomingMSGTimer?.invalidate()
        incomingMSGTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(shouldUpdateDashboard(timer:)), userInfo: ["message": message, "onChat" : onChat], repeats: false)
    }
   
    @objc func shouldUpdateDashboard(timer: Timer) {
        if let userInfo = timer.userInfo as? [String: Any] {
            if let message = userInfo["message"] as? TransactionMessage, let onChat = userInfo["onChat"] as? Bool {
                sendNotification(message: message)
                delegate?.didReceiveMessage?(message: message, onChat: onChat)
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
            
            if shouldUpdateObjectsOnView(chat: chat) {
                delegate?.didUpdateChat?(chat: chat)
            }
            
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
            
            if chat.willNotifyOnlyMentions() {
                if !message.containsMention() {
                    return
                }
            }
            
            appDelegate.sendNotification(message: message)
        }
    }
    
    func didReceiveContact(contactJson: JSON) {
        if let contact = UserContact.insertContact(contact: contactJson).0 {
            if shouldUpdateObjectsOnView(contact: contact) {
                delegate?.didUpdateContact?(contact: contact)
            }
        }
    }
    
    func didReceiveGroup(groupJson: JSON) {
        if let contacts = groupJson["new_contacts"].array {
            for c in contacts {
                let (_, _) = UserContact.insertContact(contact: c)
            }
        }

        let _ = Chat.getOrCreateChat(chat: groupJson["chat"])

        delegate?.didReceiveOrUpdateGroup?()
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
        var chat : Chat? = nil
        
        if let _ = json["contact"].dictionary, let chatJson = json["chat"].dictionary {
            if let chatObject = Chat.insertChat(chat: JSON(chatJson)) {
                chat = chatObject

                if let chat = chat {
                    CoreDataManager.sharedManager.saveContext()

                    if shouldUpdateObjectsOnView(chat: chat) {
                        delegate?.didUpdateChat?(chat: chat)
                    }
                }
            }
        }
        delegate?.didReceiveOrUpdateGroup?()

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
            
            if let chat = Chat.insertChat(chat: json["chat"]) {
                delegate?.didUpdateChat?(chat: chat)
            }
            
            didReceiveMessage(type: type, messageJson: JSON(message))
        }
    }

    
    func didReceiveInvite(inviteJson: JSON) {
        if let invite = UserInvite.insertInvite(invite: inviteJson) {
            if let contact = invite.contact {
                if shouldUpdateObjectsOnView(contact: contact) {
                    delegate?.didUpdateContact?(contact: contact)
                }
            }
        }
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

        if let del = delegate as? DashboardViewController, let vc = del.detailViewController {
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
        let _ = TransactionMessage.insertMessage(m: json)
        let amt = json["amount"].intValue
        
        if amt > 0 {
            updateBalanceIfNeeded(type: "keysend")
        }
    }
    
    func markAsSeenIfNeeded(message: TransactionMessage) {
        let outgoing = message.isOutgoing()
        
        if outgoing {
            setChatSeen(message: message, value: true)
            return
        }
        
        let isSeen = shouldMarkAsSeen(message: message)
        
        if isSeen {
            message.setAsSeen()
        }
        
        setChatSeen(message: message, value: isSeen)
    }
    
    func setChatSeen(message: TransactionMessage, value: Bool) {
        message.chat?.seen = value
        message.saveMessage()
    }
    
    func shouldMarkAsSeen(message: TransactionMessage) -> Bool {
        if !NSApplication.shared.isActive {
            return false
        }

        if let del = delegate as? DashboardViewController, let vc = del.detailViewController {
            if let chat = vc.chat, let messageChatId = message.chat?.id {
                if chat.id == messageChatId {
                    return true
                }
            } else if let contact = vc.contact, message.senderId == contact.id {
                return true
            }
        }
        return false
    }
    
    func setAppBadgeCount() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.setBadge(count: TransactionMessage.getReceivedUnseenMessagesCount())
        }
    }
}
