//
//  SphinxOnionManager+InvitesExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 25/03/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Foundation

extension SphinxOnionManager{//invites related
    
    func issueInvite(amountMsat: Int) -> String? {
        guard let seed = getAccountSeed(),
            let selfContact = UserContact.getSelfContact(),
            let nickname = selfContact.nickname 
        else {
            return nil
        }
        
        do {
            let rr = try! makeInvite(
                seed: seed,
                uniqueTime: getTimeWithEntropy(),
                state: loadOnionStateAsData(),
                host: self.server_IP,
                amtMsat: UInt64(amountMsat),
                myAlias: nickname,
                tribeHost: "\(server_IP):8801",
                tribePubkey: defaultTribePubkey
            )
            
            handleRunReturn(rr: rr)
            
            return rr.newInvite
        } catch {
            return nil
        }
    }
    
    func redeemInvite(inviteCode: String) {
        guard let seed = getAccountSeed() else{
            return
        }
        do {
            let rr = try! processInvite(
                seed: seed,
                uniqueTime: getTimeWithEntropy(),
                state: loadOnionStateAsData(),
                inviteQr: inviteCode
            )
            handleRunReturn(rr: rr)
            
            if let lsp = rr.lspHost {
                self.server_IP = lsp
            }
            
            self.stashedContactInfo = rr.inviterContactInfo
            self.stashedInitialTribe = rr.initialTribe
            self.stashedInviteCode = inviteCode
            self.stashedInviterAlias = rr.inviterAlias
        } catch {
            return
        }
    }
    
    
    func doInitialInviteSetup(){
        guard let stashedInviteCode = stashedInviteCode else{
            return
        }
        if let stashedContactInfo = stashedContactInfo {
            self.stashedContactInfo = nil
            
            makeFriendRequest(
                contactInfo: stashedContactInfo,
                inviteCode: stashedInviteCode
            )
        }
        joinInitialTribe()
    }
    
    func createContactForInvite(
        code: String,
        nickname: String
    ) {
        let contact = UserContact(context: managedContext)
        contact.id = Int(Int32(UUID().hashValue & 0x7FFFFFFF))
        contact.publicKey = ""//
        contact.isOwner = false//
        contact.nickname = nickname
        contact.createdAt = Date()
        contact.status = UserContact.Status.Pending.rawValue
        contact.createdAt = Date()
        contact.createdAt = Date()
        contact.fromGroup = false
        contact.privatePhoto = false
        contact.tipAmount = 0
        contact.sentInviteCode = try! codeFromInvite(inviteQr: code)
        
        let invite = UserInvite(context: managedContext)
        invite.inviteString = code
        invite.status = UserInvite.Status.Ready.rawValue
        contact.invite = invite
        invite.contact = contact
        
        managedContext.saveContext()
    }
    
}
