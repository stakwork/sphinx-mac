//
//  SphinxOnionManager+TribesExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 25/03/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Foundation

import Foundation
import Foundation
import CocoaMQTT
import ObjectMapper
import SwiftyJSON

extension SphinxOnionManager {//tribes related
    
    func createTribe(params: [String:Any]) {
        guard let seed = getAccountSeed() else{
            return
        }
        
        guard let tribeData = try? JSONSerialization.data(withJSONObject: params),
              let tribeJSONString = String(data: tribeData, encoding: .utf8)
        else {
            return
        }
        
        do {
            let rr = try! Sphinx.createTribe(
                seed: seed,
                uniqueTime: getTimeWithEntropy(),
                state: loadOnionStateAsData(),
                tribeServerPubkey: tribeServerPubkey,
                tribeJson: tribeJSONString
            )
            
            handleRunReturn(rr: rr)
        } catch {}
    }
    
    func joinTribe(
        tribePubkey: String,
        routeHint: String,
        joinAmountMsats: Int = 1000,
        alias: String? = nil,
        isPrivate: Bool = false
    ) {
        guard let seed = getAccountSeed() else{
            return
        }
        do {
            let rr = try! Sphinx.joinTribe(
                seed: seed,
                uniqueTime: getTimeWithEntropy(),
                state: loadOnionStateAsData(),
                tribePubkey: tribePubkey,
                tribeRouteHint: routeHint,
                alias: alias ?? "test",
                amtMsat: UInt64(joinAmountMsats),
                isPrivate: isPrivate
            )
            
            DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
                self.handleRunReturn(rr: rr)
            })
        } catch {}
    }
    
    func extractHostAndTribeIdentifier(from urlString: String) -> (String, String)? {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return nil
        }
        
        guard let host = url.host,
              let port = url.port else {
            print("URL does not have a host")
            return nil
        }
        
        let pathComponents = url.pathComponents
        guard let tribeIdentifier = pathComponents.last, tribeIdentifier != "/" else {
            print("URL does not have a tribe identifier")
            return nil
        }
        
        print("Host: \(host)")
        print("Tribe Identifier: \(tribeIdentifier)")
        return ("\(host):\(port)",tribeIdentifier)
    }
    
    func joinInitialTribe() {
        guard let tribeURL = self.stashedInitialTribe,
              let (host, pubkey) = extractHostAndTribeIdentifier(from: tribeURL) 
        else {
            return
        }
        
        GroupsManager.sharedInstance.fetchTribeInfo(
            host: host,
            uuid: pubkey,
            useSSL: false,
            completion: { groupInfo in
                let qrString = "action=tribeV2&pubkey=\(pubkey)&host=\(host)"
                var tribeInfo = GroupsManager.TribeInfo(ownerPubkey:pubkey, host: host,uuid: pubkey)
                self.stashedInitialTribe = nil
                
                GroupsManager.sharedInstance.update(
                    tribeInfo: &tribeInfo,
                    from: groupInfo
                )
                
                GroupsManager.sharedInstance.finalizeTribeJoin(
                    tribeInfo: tribeInfo,
                    qrString: qrString
                )
            },
            errorCallback: {}
        )
    }
    
    func exitTribe(tribeChat: Chat) {
        let _ = sendMessage(
            to: nil,
            content: "",
            chat: tribeChat,
            msgType: UInt8(TransactionMessage.TransactionMessageType.groupLeave.rawValue),
            threadUUID: nil,
            replyUUID: nil
        )
    }
    
    func getTribeMembers(
        tribeChat: Chat,
        completion: (([String: AnyObject]) -> ())?
    ){
        guard let seed = getAccountSeed() else{
            return
        }
        do{
            let rr = try! listTribeMembers(
                seed: seed,
                uniqueTime: getTimeWithEntropy(),
                state: loadOnionStateAsData(),
                tribeServerPubkey: tribeServerPubkey,
                tribePubkey: tribeChat.ownerPubkey ?? ""
            )
            stashedCallback = completion
            handleRunReturn(rr: rr)
        } catch {}
    }
    
    func kickTribeMember(
        pubkey: String,
        chat:Chat
    ){
        do{
            let _ = sendMessage(
                to: nil,
                content: pubkey,
                chat: chat,
                msgType: UInt8(TransactionMessage.TransactionMessageType.groupKick.rawValue),
                recipPubkey: tribeServerPubkey,
                threadUUID: nil,
                replyUUID: nil
            )
        } catch {}
    }
    
    func approveOrRejectTribeJoinRequest(
        requestUuid: String,
        chat: Chat,
        type: TransactionMessage.TransactionMessageType
    ){
        if (type.rawValue == TransactionMessage.TransactionMessageType.memberApprove.rawValue ||
            type.rawValue == TransactionMessage.TransactionMessageType.memberReject.rawValue) == false
        {
            return
        }
        
        let _ = sendMessage(
            to: nil,
            content: "",
            chat: chat,
            msgType: UInt8(type.rawValue),
            recipPubkey: tribeServerPubkey,
            threadUUID: nil,
            replyUUID: requestUuid
        )
    }
    
    
    
    func deleteTribe(tribeChat:Chat){
        do{
            let _ = sendMessage(
                to: nil,
                content: "",
                chat: tribeChat,
                msgType: UInt8(TransactionMessage.TransactionMessageType.groupDelete.rawValue),
                recipPubkey: tribeServerPubkey,
                threadUUID: nil,
                replyUUID: nil
            )
        } catch {}
    }
}