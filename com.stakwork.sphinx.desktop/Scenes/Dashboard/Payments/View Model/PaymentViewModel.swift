//
//  PaymentViewModel.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON

class PaymentViewModel : NSObject {
    
    public struct PaymentObject {
        var memo: String?
        var encryptedMemo: String?
        var remoteEncryptedMemo: String?
        var amount: Int?
        var destinationKey: String?
        var message: String?
        var encryptedMessage: String?
        var remoteEncryptedMessage: String?
        var muid: String?
        var dim: String?
        var transactionMessage: TransactionMessage?
        var chat: Chat?
        var contacts = [UserContact]()
        var mode: PaymentMode?
    }
    
    enum PaymentMode: Int {
        case Request
        case Payment
    }
    
    var currentPayment : PaymentObject!
    
    init(
        chat: Chat? = nil,
        contact: UserContact? = nil,
        message: TransactionMessage? = nil,
        mode: PaymentMode
    ) {
        super.init()
        
        self.currentPayment = PaymentObject()
        self.currentPayment.chat = chat
        self.currentPayment.transactionMessage = message
        self.currentPayment.mode = mode
        
        if let contact = contact {
            setContacts(contacts: [contact])
        }
    }
    
    func setContacts(contacts: [UserContact]? = nil) {
        self.currentPayment.contacts = []
        
        if let contacts = contacts, contacts.count > 0 {
            self.currentPayment.contacts = contacts
        } else if let chat = currentPayment.chat, let contact = chat.getContact() {
            self.currentPayment.contacts = [contact]
        }
    }
    
    func isTribePayment() -> Bool {
        return currentPayment.transactionMessage != nil
    }
    
    func validateInvoice() -> Bool {
        guard let memo = currentPayment.memo else {
            return true
        }
        
        guard let contact = currentPayment.contacts.first else {
            return memo.isValidLengthMemo()
        }
        
        return false
    }
    
    func validatePayment() -> Bool {
        guard let _ = currentPayment.transactionMessage else {
            return true
        }
        
        guard let _ = currentPayment.message else {
            return true
        }
        
        if currentPayment.contacts.count < 1 {
            return false
        }
        
        return true
    }
    
    func shouldSendDirectPayment(callback: @escaping () -> (), errorCallback: @escaping (String?) -> ()) {
        guard let chat = currentPayment.chat else {
            errorCallback("generic.error.message".localized)
            return
        }
        
        let parameters = getParams()
        
        SphinxOnionManager.sharedInstance.sendDirectPaymentMessage(params: parameters, chat: chat, completion: { success, _ in
            if (success){
                callback()
            } else {
                errorCallback("generic.error.message".localized)
            }
        })
    }
    
    func shouldCreateInvoice(
        callback: @escaping (String?) -> (),
        shouldDisplayAsQR: Bool = false,
        errorCallback: @escaping (String?) -> ()
    ) {
        if !validateInvoice() {
            errorCallback("memo.too.large".localized)
            return
        }
        
        if let paymentAmount = currentPayment.amount,
           let invoice = SphinxOnionManager.sharedInstance.createInvoice(
            amountMsat: paymentAmount * 1000,
            description: currentPayment.memo ?? ""
           )
        {
            if let contact = currentPayment.contacts.first, let chat = currentPayment.chat {
                SphinxOnionManager.sharedInstance.sendInvoiceMessage(
                    contact: contact,
                    chat: chat,
                    invoiceString: invoice
                )
                callback(nil)
            } else {
                callback(invoice)
            }
        } else {
            errorCallback("generic.error.message".localized)
        }
    }
    
    func createLocalMessages(message: JSON?) -> (TransactionMessage?, Bool) {
        if let message = message {
            if let messageObject = TransactionMessage.insertMessage(
                m: message,
                existingMessage: TransactionMessage.getMessageWith(id: message["id"].intValue)
            ).0 {
                messageObject.setPaymentInvoiceAsPaid()
                return (messageObject, true)
            }
        }
        return (nil, false)
    }
    
    func getParams() -> [String: AnyObject] {
        var parameters = [String : AnyObject]()
        
        if let amount = currentPayment.amount {
            parameters["amount"] = amount as AnyObject?
        }
        
        if let encryptedMemo = currentPayment.encryptedMemo, let remoteEncryptedMemo = currentPayment.remoteEncryptedMemo {
            parameters["memo"] = encryptedMemo as AnyObject?
            parameters["remote_memo"] = remoteEncryptedMemo as AnyObject?
        } else if let memo = currentPayment.memo {
            parameters["memo"] = memo as AnyObject?
        }
        
        if let publicKey = currentPayment.destinationKey {
            parameters["destination_key"] = publicKey as AnyObject?
        }
        
        if let muid = currentPayment.muid {
            parameters["muid"] = muid as AnyObject?
            parameters["media_type"] = "image/png" as AnyObject?
        }
        
        if let dim = currentPayment.dim {
            parameters["dimensions"] = dim as AnyObject?
        }
        
        let contacts = currentPayment.contacts
        
        if contacts.count > 0 {
            if let chat = currentPayment.chat {
                parameters["chat_id"] = chat.id as AnyObject?
            } else if contacts.count > 0 {
                let contact = contacts[0]
                parameters["contact_id"] = contact.id as AnyObject?
            }
            
            if currentPayment.chat?.isGroup() ?? false {
                parameters["contact_ids"] = contacts.map { $0.id } as AnyObject?
            }
            
            if let text = currentPayment.message {
                let encryptionManager = EncryptionManager.sharedInstance
                let encryptedOwnMessage = encryptionManager.encryptMessageForOwner(message: text)
                parameters["text"] = encryptedOwnMessage as AnyObject?
                
                if currentPayment.chat?.isGroup() ?? false {
                    var encryptedDictionary = [String : String]()
                    
                    for c in contacts {
                        let (_, encryptedContactMessage) = encryptionManager.encryptMessage(message: text, for: c)
                        encryptedDictionary["\(c.id)"] = encryptedContactMessage
                    }
                    
                    if encryptedDictionary.count > 0 {
                        parameters["remote_text_map"] = encryptedDictionary as AnyObject?
                    }
                } else {
                    let contact = contacts[0]
                    let (_, encryptedContactMessage) = encryptionManager.encryptMessage(message: text, for: contact)
                    parameters["remote_text"] = encryptedContactMessage as AnyObject?
                }
            }
        } else {
            if let message = currentPayment.message {
                parameters["text"] = message as AnyObject?
            }
        }
        
        return parameters
    }
}
