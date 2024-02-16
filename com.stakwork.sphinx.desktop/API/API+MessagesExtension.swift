//
//  APIMessagesExtension.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    func sendMessage(
        params: [String: AnyObject],
        callback:@escaping MessageObjectCallback,
        errorCallback:@escaping EmptyCallback
    ) {
        
        guard let request = getURLRequest(route: "/messages", params: params as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }

        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let response = json["response"] as? NSDictionary {
                        callback(JSON(response))
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func getMessagesPaginated(
        page: Int,
        date: Date,
        callback: @escaping GetMessagesPaginatedCallback,
        errorCallback: @escaping EmptyCallback
    ){
        
        let itemsPerPage = ChatListViewModel.kMessagesPerPage
        let offset = (page - 1) * itemsPerPage
        var route = "/msgs?offset=\(offset)&limit=\(itemsPerPage)&order=desc"
        
        let dateString = (lastSeenMessagesDate ?? Date(timeIntervalSince1970: 0))
        if let dateString = dateString.getStringFromDate(format:"yyyy-MM-dd HH:mm:ss").percentEscaped {
            route = "\(route)&date=\(dateString)"
        }
        
        guard let request = getURLRequest(route: route, method: "GET") else {
            errorCallback()
            return
        }
        
        cancellableRequest(request, type: .messages) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        let newMessages = JSON(response["new_messages"] ?? []).arrayValue
                        let messagesTotal = JSON(response["new_messages_total"] ?? -1).intValue
                        
                        if ((newMessages.count > 0 || page > 1) && newMessages.count < itemsPerPage) {
                            //If is last page date should be tracked
                            self.lastSeenMessagesDate = date
                            ChatListViewModel.restoreRunning = false
                        }
                        
                        callback(messagesTotal, newMessages)
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    func deleteMessage(
        messageId: Int,
        callback:@escaping DeleteMessageCallback
    ) {
        
        guard let request = getURLRequest(route: "/message/\(messageId)", method: "DELETE") else {
            callback(false, JSON())
            return
        }

        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(true, JSON(response))
                    } else {
                        callback(false, JSON())
                    }
                }
            case .failure(_):
                callback(false, JSON())
            }
        }
    }
    
    func sendDirectPayment(
        params: [String: AnyObject],
        callback:@escaping DirectPaymentResultsCallback,
        errorCallback:@escaping ErrorCallback
    ) {
        
        guard let request = getURLRequest(route: "/payment", params: params as NSDictionary?, method: "POST") else {
            callback(false)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let _ = json["success"] as? Bool {
                        if let response = json["response"] as? NSDictionary {
                            if let _ = response["destination_key"] as? String {
                                callback(nil)
                            } else {
                                callback(JSON(response))
                            }
                            return
                        }
                    }
                }
                errorCallback(
                    ((data as? NSDictionary)?["error"] as? String) ?? "Unknown reason"
                )
            case .failure(_):
                errorCallback("Unknown reason")
            }
        }
    }
    
    public func createInvoice(
        parameters: [String : AnyObject],
        callback: @escaping CreateInvoiceCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        
        guard let request = getURLRequest(route: "/invoices", params: parameters as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        if let invoiceString = response["invoice"] as? String {
                            callback(nil, invoiceString)
                        } else {
                            callback(JSON(response), nil)
                        }
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func payInvoice(
        parameters: [String : AnyObject],
        callback: @escaping PayInvoiceCallback,
        errorCallback: @escaping ErrorCallback
    ) {
        
        guard let request = getURLRequest(route: "/invoices", params: parameters as NSDictionary?, method: "PUT") else {
            errorCallback("Unknown reason")
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(JSON(response))
                        return
                    }
                }
                errorCallback(
                    ((data as? NSDictionary)?["error"] as? String) ?? "Unknown reason"
                )
            case .failure(_):
                errorCallback("Unknown reason")
            }
        }
    }
    
    public func payLsat(
        parameters: [String : AnyObject],
        callback: @escaping PayInvoiceCallback,
        errorCallback: @escaping EmptyCallback
    ) {

        guard let request = getURLRequest(route: "/lsats", params: parameters as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(JSON(response))
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func saveGraphData(
        parameters: [String : AnyObject],
        callback: @escaping PayInvoiceCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        print("requesting data")
        guard let request = getURLRequest(route: "/action_history", params: parameters as NSDictionary?, method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(JSON(response))
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func getActiveLsat(
        issuer: String? = nil,
        callback: @escaping PayInvoiceCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        print("requesting Lsat")
        
        var urlString = "/active_lsat"
        
        if let issuer = issuer {
                urlString += "?issuer=\(issuer)"
            }
        
        guard let request = getURLRequest(route: urlString, method: "GET") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(JSON(response))
                    } else {
                        print()
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func getLsatList(
        callback: @escaping PayInvoiceCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        print("requesting Lsat")
        guard let request = getURLRequest(route: "/lsats", method: "GET") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(JSON(response))
                    } else {
                        print()
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func deleteLsat(
        lsat: LSATObject,
        callback: @escaping EmptyCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let valid_id = lsat.identifier else{
            errorCallback()
            return
        }
        
        print("deleting Lsat")
        guard let request = getURLRequest(route: "/lsats/\(valid_id)", method: "DELETE") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool,
                        success {
                        callback()
                    } else {
                        print()
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    
    public func getPersonData(
        callback: @escaping GetPersonDataCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        guard let request = getURLRequest(route: "/person_data", method: "GET") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(JSON(response))
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func updateLsat(
        identifier: String,
        parameters: [String : AnyObject],
        callback: @escaping PayInvoiceCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        print(parameters)
        guard let request = getURLRequest(route: "/lsats/\(identifier)",params: parameters as NSDictionary?, method: "PUT") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? String, success {
                        callback(JSON(response))
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
    
    public func setChatMessagesAsSeen(
        chatId: Int,
        callback: @escaping SuccessCallback
    ) {
        
        guard let request = getURLRequest(route: "/messages/\(chatId)/read", method: "POST") else {
            callback(false)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback(true)
                    } else {
                        callback(false)
                    }
                }
            case .failure(_):
                callback(false)
            }
        }
    }
    
    public func toggleChatReadUnread(
        chatId: Int,
        shouldMarkAsUnread:Bool,
        callback: @escaping SuccessCallback
    ) {
        var params: [String: AnyObject] = [:]
        params["shouldMarkAsUnread"] = shouldMarkAsUnread as AnyObject
        
        guard let request = getURLRequest(
            route: "/messages/\(chatId)/toggleChatReadUnread",
            params: params as NSDictionary,
            method: "POST"
        ) else {
            callback(false)
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback(true)
                    } else {
                        callback(false)
                    }
                }
            case .failure(_):
                callback(false)
            }
        }
    }
    
    func getMessageBy(
        messageUUID: String,
        callback: @escaping MessageObjectCallback,
        errorCallback: @escaping EmptyCallback
    ) {
        
        guard let request = getURLRequest(route: "/message/\(messageUUID)", params: nil, method: "GET") else {
            errorCallback()
            return
        }

        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        if let message = response["message"] {
                            callback(JSON(message))
                        } else {
                            errorCallback()
                        }
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
}
