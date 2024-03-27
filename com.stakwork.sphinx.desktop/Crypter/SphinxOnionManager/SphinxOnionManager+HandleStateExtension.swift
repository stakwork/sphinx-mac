//
//  SphinxOnionManager+HandleStateExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 25/03/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Foundation
import MessagePack
import CocoaMQTT
import ObjectMapper
import SwiftyJSON


extension SphinxOnionManager {
    func handleRunReturn(
        rr: RunReturn,
        publishDelay: Double = 0.5,
        completion: (([String:AnyObject]) ->())? = nil
    ){
        print("handleRR rr:\(rr)")
        
        if let sm = rr.stateMp{
            let _ = storeOnionState(inc: sm.bytes)
        }
        
        if let newTribe = rr.newTribe {
            print(newTribe)
            NotificationCenter.default.post(
                name: .newTribeCreationComplete,
                object: nil,
                userInfo: ["tribeJSON" : newTribe]
            )
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: publishDelay, completion: {
            for i in 0..<rr.topics.count{
                self.pushRRTopic(
                    topic: rr.topics[i],
                    payloadData: rr.payloads[i]
                )
            }
        })
        
        
        if let mci = rr.myContactInfo {
            let components = mci.split(separator: "_").map({String($0)})
            
            if let components = parseContactInfoString(routeHint: mci),
               UserContact.getContactWithDisregardStatus(pubkey: components.0) == nil
            {//only add this if we don't already have a "self" contact
                createSelfContact(
                    scid: components.2,
                    serverPubkey: components.1,
                    myOkKey: components.0
                )
            }
        }
        
        if let balance = rr.newBalance {
            UserData.sharedInstance.save(balance: balance)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                NotificationCenter.default.post(
                    Notification(
                        name: .onBalanceDidChange,
                        object: nil,
                        userInfo: ["balance" : balance])
                )
            })
        }
        
        processGenericMessages(rr: rr)
        processKeyExchangeMessages(rr: rr)
        
        // Assuming 'rr.tribeMembers' is a JSON string similar to the 'po map.JSON' output you've shown
        if let tribeMembersString = rr.tribeMembers,
           let jsonData = tribeMembersString.data(using: .utf8),
           let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] 
        {
            var confirmedMembers: [TribeMembersRRObject] = []
            var pendingMembers: [TribeMembersRRObject] = []
            
            // Parse confirmed members
            if let confirmedArray = jsonDict["confirmed"] as? [[String: Any]] {
                confirmedMembers = confirmedArray.compactMap { Mapper<TribeMembersRRObject>().map(JSONObject: $0) }
            }
            
            // Parse pending members (assuming a similar structure for actual pending members)
            if let pendingArray = jsonDict["pending"] as? [[String: Any]] {
                pendingMembers = pendingArray.compactMap { Mapper<TribeMembersRRObject>().map(JSONObject: $0) }
            }
            
            // Assuming 'stashedCallback' expects a dictionary with confirmed and pending members
            if let completion = stashedCallback {
                completion(["confirmedMembers": confirmedMembers as AnyObject, "pendingMembers": pendingMembers as AnyObject])
                stashedCallback = nil
            }
        }
        
        
        if let sentStatus = rr.sentStatus {
            print(sentStatus)
            // Assuming sentStatus is a JSON string, convert it to a dictionary
            if let data = sentStatus.data(using: .utf8) {
                do {
                    // Decode the JSON string into a dictionary
                    if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any?] {
                        // Check if payment_hash exists and is not nil
                        if let paymentHash = dictionary["payment_hash"] as? String, !paymentHash.isEmpty,
                           let preimage = dictionary["preimage"] as? String,
                           !preimage.isEmpty
                        {
                            // Post to the notification center
                            NotificationCenter.default.post(
                                name: .invoiceIPaidSettled,
                                object: nil,
                                userInfo: dictionary as [String: Any]
                            )
                        }
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }
        
        if let settledStatus = rr.settledStatus{
            print("settledStatus:\(rr.settledStatus ?? "")")
        }
        
        if let error = rr.error {
            print("ERROR:\(error)")
        }
        
        purgeObsoleteState(keys: rr.stateToDelete)
    }
    
    func pushRRTopic(
        topic: String,
        payloadData: Data?
    ){
        let byteArray: [UInt8] = payloadData != nil ? [UInt8](payloadData!) : [UInt8]()
        
        print("pushRRTopic | topic:\(topic) | payload:\(byteArray)")
        self.mqtt.publish(
            CocoaMQTTMessage(
                topic: topic,
                payload: byteArray
            )
        )
    }
    
    func timestampToDate(timestamp: UInt64) -> Date? {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        return date
    }

    func isGroupAction(type: UInt8) -> Bool {
        let throwAwayMessage = TransactionMessage(context: managedContext)
        throwAwayMessage.type = Int(type)
        return throwAwayMessage.isGroupActionMessage()
    }
        
    //MARK: Processes key exchange messages (friend requests) between contacts
    func processKeyExchangeMessages(rr: RunReturn){
        for msg in rr.msgs {
            if let sender = msg.sender,
               let csr = ContactServerResponse(JSONString: sender),
               let senderPubkey = csr.pubkey
            {
                print(sender)
                let type = msg.type ?? 255
                if type == TransactionMessage.TransactionMessageType.contactKeyConfirmation.rawValue // incoming key exchange confirmation 
                {
                    // if contact exists it's a key exchange response from them or it exists already
                    guard let existingContact = UserContact.getContactWithDisregardStatus(
                        pubkey: senderPubkey
                    ) ?? UserContact.getContactWithInvitCode(inviteCode:"") else {
                        //no existing contact!
                        return
                    }
                    
                    NotificationCenter.default.post(
                        Notification(
                            name: .newContactWasRegisteredWithServer,
                            object: nil,
                            userInfo: ["contactPubkey" : existingContact.publicKey as Any]
                        )
                    )
                    
                    existingContact.nickname = csr.alias
                    existingContact.avatarUrl = csr.photoUrl
                    
                    if existingContact.getChat() == nil {
                        createChat(for: existingContact)
                    }
                    
                    existingContact.nickname = csr.alias
                    existingContact.status = UserContact.Status.Confirmed.rawValue
                    
                    CoreDataManager.sharedManager.saveContext()
                    
                } else if type == TransactionMessage.TransactionMessageType.contactKey.rawValue, // incoming key exchange request
                        UserContact.getContactWithDisregardStatus(pubkey: senderPubkey) == nil,//don't respond to requests if already exists
                        let newContactRequest = createNewContact(
                            pubkey: senderPubkey,
                            nickname: csr.alias,
                            photo_url: csr.photoUrl,
                            person: csr.person,
                            code: csr.code
                        )
                { //new contact from a key exchange message
                    NotificationCenter.default.post(
                        Notification(
                            name: .newContactWasRegisteredWithServer, 
                            object: nil,
                            userInfo: ["contactPubkey" : newContactRequest.publicKey as Any]
                        )
                    )
                    newContactRequest.status = UserContact.Status.Confirmed.rawValue
                    createChat(for: newContactRequest)
                    managedContext.saveContext()
                }
            }
        }
        
    }

    func isIndexedSentMessageFromMe(msg: Msg) -> Bool {
        if let _ = msg.uuid,
           let _ = msg.index
        {
            return true
        }
        return false
    }

    var mutationKeys: [String] {
        get {
            if let onionState: String = UserDefaults.Keys.onionState.get() {
                return onionState.components(separatedBy: ",")
            }
            return []
        }
        set {
            UserDefaults.Keys.onionState.set(
                newValue.joined(separator: ",")
            )
        }
    }
    
    func loadOnionStateAsData() -> Data {
        let state = loadOnionState()
        
        var mpDic = [MessagePackValue:MessagePackValue]()

        for (key, value) in state {
            mpDic[MessagePackValue(key)] = MessagePackValue(Data(value))
        }
        
        let stateBytes = pack(
            MessagePackValue(mpDic)
        ).bytes
        
        return Data(stateBytes)
    }

    private func loadOnionState() -> [String: [UInt8]] {
        var state:[String: [UInt8]] = [:]
        
        for key in mutationKeys {
            if let value = UserDefaults.standard.object(forKey: key) as? [UInt8] {
                state[key] = value
            }
        }
        return state
    }

    func storeOnionState(inc: [UInt8]) -> [NSNumber] {
        let muts = try? unpack(Data(inc))
        
        guard let mutsDictionary = (muts?.value as? MessagePackValue)?.dictionaryValue else {
            return []
        }
        
        persist_muts(muts: mutsDictionary)

        return []
    }

    private func persist_muts(muts: [MessagePackValue: MessagePackValue]) {
        var keys: [String] = []
        
        for  mut in muts {
            if let key = mut.key.stringValue, let value = mut.value.dataValue?.bytes {
                keys.append(key)
                UserDefaults.standard.removeObject(forKey: key)
                UserDefaults.standard.synchronize()
                UserDefaults.standard.set(value, forKey: key)
                UserDefaults.standard.synchronize()
            }
        }
        
        keys.append(contentsOf: mutationKeys)
        mutationKeys = keys
    }
    
    func purgeObsoleteState(keys:[String]){
        for key in keys{
            UserDefaults.standard.removeObject(forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
}

struct ContactServerResponse: Mappable {
    var pubkey: String?
    var alias: String?
    var photoUrl: String?
    var person: String?
    var code: String?

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        pubkey    <- map["pubkey"]
        alias     <- map["alias"]
        photoUrl  <- map["photo_url"]
        person    <- map["person"]
        code <- map["code"]
    }
}

struct MessageInnerContent: Mappable {
    var content:String?
    var replyUuid:String?=nil
    var threadUuid:String?=nil
    var mediaKey:String?=nil
    var mediaToken:String?=nil
    var mediaType:String?=nil
    var muid:String?=nil
    var originalUuid:String?=nil
    var date:Int?=nil
    var invoice:String?=nil
    var paymentHash:String?=nil
    var amount:Int?=nil

    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        content    <- map["content"]
        replyUuid <- map["replyUuid"]
        threadUuid <- map["threadUuid"]
        mediaToken <- map["mediaToken"]
        mediaType <- map["mediaType"]
        mediaKey <- map["mediaKey"]
        muid <- map["muid"]
        date <- map["date"]
        originalUuid <- map["originalUuid"]
        invoice <- map["invoice"]
        paymentHash <- map["paymentHash"]
        amount <- map["amount"]
    }
    
}

struct GenericIncomingMessage: Mappable {
    var content:String?
    var amount:Int?
    var senderPubkey:String?=nil
    var uuid:String?=nil
    var originalUuid:String?=nil
    var index:String?=nil
    var replyUuid:String?=nil
    var threadUuid:String?=nil
    var mediaKey:String?=nil
    var mediaToken:String?=nil
    var mediaType:String?=nil
    var muid:String?=nil
    var date:Int?=nil
    var invoice:String?=nil
    var paymentHash:String?=nil

    init?(map: Map) {}
    
    init(msg:Msg){
        if let sender = msg.sender,
           let csr = ContactServerResponse(JSONString: sender){
            self.senderPubkey = csr.pubkey
        }
        
        var innerContentAmount : UInt64? = nil
        if let message = msg.message,
           let innerContent = MessageInnerContent(JSONString: message){
            self.content = innerContent.content
            self.replyUuid = innerContent.replyUuid
            self.threadUuid = innerContent.threadUuid
            self.mediaKey = innerContent.mediaKey
            self.mediaToken = innerContent.mediaToken
            self.mediaType = innerContent.mediaType
            self.muid = innerContent.muid
            self.originalUuid = innerContent.originalUuid
            self.date = innerContent.date
            self.invoice = innerContent.invoice
            self.paymentHash = innerContent.paymentHash
            innerContentAmount = UInt64(innerContent.amount ?? 0)
        }
        self.amount = Int((msg.msat ?? innerContentAmount) ?? 0)
        self.uuid = msg.uuid
        self.index = msg.index
    }

    mutating func mapping(map: Map) {
        content    <- map["content"]
        amount     <- map["amount"]
        replyUuid <- map["replyUuid"]
        threadUuid <- map["threadUuid"]
        mediaToken <- map["mediaToken"]
        mediaType <- map["mediaType"]
        mediaKey <- map["mediaKey"]
        muid <- map["muid"]
        
    }
}

struct TribeMembersRRObject: Mappable {
    var pubkey:String? = nil
    var routeHint:String? = nil
    var alias:String? = nil
    var contactKey:String? = nil
    var is_owner: Bool = false
    var status:String? = nil

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        pubkey    <- map["pubkey"]
        alias    <- map["alias"]
        routeHint    <- map["route_hint"]
        contactKey    <- map["contact_key"]
    }
}