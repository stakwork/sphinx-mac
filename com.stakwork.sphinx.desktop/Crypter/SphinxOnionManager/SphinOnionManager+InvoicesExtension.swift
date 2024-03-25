//
//  SphinOnionManager+InvoicesExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 25/03/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Foundation

///invoices related
extension SphinxOnionManager {
    
    func createInvoice(
        amountMsat: Int,
        description: String? = nil
    ) -> String? {
        guard let seed = getAccountSeed(),
            let selfContact = UserContact.getSelfContact(),
            let _ = selfContact.nickname else {
            return nil
        }
        
        let rr = try! makeInvoice(
            seed: seed,
            uniqueTime: getTimeWithEntropy(),
            state: loadOnionStateAsData(),
            amtMsat: UInt64(amountMsat),
            description: description ?? ""
        )
        
        handleRunReturn(rr: rr)
        
        return rr.invoice
    }
    
    func payInvoice(invoice: String) {
        guard let seed = getAccountSeed() else{
            return
        }
        
        let rr = try! Sphinx.payInvoice(
            seed: seed,
            uniqueTime: getTimeWithEntropy(),
            state: loadOnionStateAsData(),
            bolt11: invoice,
            overpayMsat: nil
        )
        
        handleRunReturn(rr: rr)
    }
    
    func sendPaymentOfInvoiceMessage(message: TransactionMessage) {
        guard message.type == TransactionMessage.TransactionMessageType.payment.rawValue,
              let invoice = message.invoice,
              let seed = getAccountSeed(),
              let selfContact = UserContact.getSelfContact(),
              let chat = message.chat,
              let nickname = selfContact.nickname ?? chat.name else{
            return
        }
        let rr = try! payContactInvoice(
            seed: seed,
            uniqueTime: getTimeWithEntropy(),
            state: loadOnionStateAsData(),
            bolt11: invoice,
            myAlias: nickname,
            myImg: selfContact.avatarUrl ?? "",
            isTribe: false
        )
        handleRunReturn(rr: rr)
    }
    
    
    func sendInvoiceMessage(
        contact: UserContact,
        chat: Chat,
        invoiceString: String
    ){
        let type = TransactionMessage.TransactionMessageType.invoice.rawValue
        
        let result = self.sendMessage(
            to: contact,
            content: "",
            chat: chat,
            msgType: UInt8(type),
            threadUUID: nil,
            replyUUID: nil,
            invoiceString: invoiceString
        )
    }
}

