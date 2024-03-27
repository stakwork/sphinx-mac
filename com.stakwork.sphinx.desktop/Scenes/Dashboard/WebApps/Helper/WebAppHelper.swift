//
//  WebAppHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 19/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import WebKit
import SwiftyJSON
import ObjectMapper

protocol WebAppHelperDelegate : NSObject{
    func setBudget(budget:Int)
}

class WebAppHelper : NSObject {
    
    
    public let messageHandler = "sphinx"
    
    var webView : WKWebView! = nil
    var authorizeHandler: (([String: AnyObject]) -> ())! = nil
    var authorizeBudgetHandler: (([String: AnyObject]) -> ())! = nil
    
    var persistingValues: [String: AnyObject] = [:]
    var delegate : WebAppHelperDelegate? = nil
    
    var lsatList = [LSATObject]()
    
    func setWebView(
        _ webView: WKWebView,
        authorizeHandler: @escaping (([String: AnyObject]) -> ()),
        authorizeBudgetHandler: @escaping (([String: AnyObject]) -> ())
    ) {
        self.webView = webView
        self.authorizeHandler = authorizeHandler
        self.authorizeBudgetHandler = authorizeBudgetHandler
    }
}

extension WebAppHelper : WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == messageHandler {
            guard let dict = message.body as? [String: AnyObject] else {
                return
            }
    
            if let type = dict["type"] as? String {
                switch(type) {
                case "AUTHORIZE":
                    authorizeHandler(dict)
                    break
                case "SETBUDGET":
                    saveValue(dict["amount"] as AnyObject, for: "budget")
                    authorizeBudgetHandler(dict)
                    break
                case "KEYSEND":
                    sendKeySend(dict)
                    break
                case "UPDATED":
                    sendUpdatedMessage(dict)
                    NotificationCenter.default.post(name: .onBalanceDidChange, object: nil)
                    break
                case "RELOAD":
                    sendReloadMessage(dict)
                    break
                case "PAYMENT":
                    sendPayment(dict)
                    break
                case "LSAT":
                    saveLSAT(dict)
                    break
                case "SAVEDATA":
                    saveGraphData(dict)
                case "GETLSAT":
                    getActiveLsat(dict)
                    break
                case "UPDATELSAT":
                    updateLsat(dict)
                    break
                case "GETPERSONDATA":
                    getPersonData(dict)
                    break
                case "SIGN":
                    signMessage(dict)
                    break
                case "GETBUDGET":
                    getBudget(dict)
                    break
                default:
                    defaultAction(dict)
                    break
                }
            }
        }
    }
    
    func listLSats(completion: @escaping (Bool)->()){
        API.sharedInstance.getLsatList(callback: {results in
            let lsats = results["lsats"]
            print(lsats)
            for lsat in lsats{
                if let json = JSON(lsat.1).rawValue as? [String:Any],
                let lsat_object = Mapper<LSATObject>().map(JSON: json){
                    print(lsat_object)
                    self.lsatList.append(lsat_object)
                }
            }
            completion(true)
        }, errorCallback: {
            completion(false)
        })
    }
    
    func jsonStringWithObject(obj: AnyObject) -> String? {
        let jsonData  = try? JSONSerialization.data(withJSONObject: obj, options: JSONSerialization.WritingOptions(rawValue: 0))
        
        if let jsonData = jsonData {
            return String(data: jsonData, encoding: .utf8)
        }
        
        return nil
    }
    
    func sendMessage(dict: [String: AnyObject]) {
        if let string = jsonStringWithObject(obj: dict as AnyObject) {
            let javascript = "window.sphinxMessage('\(string)')"
            webView.evaluateJavaScript(javascript, completionHandler: nil)
        }
    }
    
    func setTypeApplicationAndPassword(params: inout [String: AnyObject], dict: [String: AnyObject]) {
        let password = EncryptionManager.randomString(length: 16)
        saveValue(password as AnyObject, for: "password")
        
        params["type"] = dict["type"] as AnyObject
        params["application"] = dict["application"] as AnyObject
        params["password"] = password as AnyObject
    }
    
    //AUTHORIZE
    func authorizeWebApp(amount: Int, dict: [String: AnyObject], completion: @escaping () -> ()) {
        if let challenge = dict["challenge"] as? String {
            signChallenge(amount: amount, challenge: challenge, dict: dict, completion: completion)
        } else {
            sendAuthorizeMessage(amount: amount, dict: dict, completion: completion)
        }
    }
    
    // AUTHORIZE Without Budget
    func authorizeNoBudget( dict: [String: AnyObject], completion: @escaping () -> ()) {
        sendAuthorizeMessage( dict: dict, completion: completion)
    }
    
    func sendAuthorizeMessage(amount: Int? = nil, signature: String? = nil, dict: [String: AnyObject], completion: @escaping () -> ()) {
        if let pubKey = UserData.sharedInstance.getUserPubKey() {
            var params: [String: AnyObject] = [:]
            setTypeApplicationAndPassword(params: &params, dict: dict)
            
            params["pubkey"] = pubKey as AnyObject
            
            saveValue(pubKey as AnyObject, for: "pubkey")
            
            if let signature = signature {
                params["signature"] = signature as AnyObject
            }
            
            if let amount = amount {
                params["budget"] = amount as AnyObject
                saveValue(amount as AnyObject, for: "budget")
            }
            
            sendMessage(dict: params)
            completion()
        }
    }
    
    func signChallenge(amount: Int, challenge: String, dict: [String: AnyObject], completion: @escaping () -> ()) {
        guard let sig = SphinxOnionManager.sharedInstance.signChallenge(challenge: challenge) else{
            return
        }
        self.sendAuthorizeMessage(amount: amount, signature: sig, dict: dict, completion: completion)
    }
    
    //UPDATED
    func sendUpdatedMessage(_ dict: [String: AnyObject]) {
        var params: [String: AnyObject] = [:]
        setTypeApplicationAndPassword(params: &params, dict: dict)
        sendMessage(dict: params)
    }
    
    //RELOAD
    func sendReloadMessage(_ dict: [String: AnyObject]) {
        let (success, budget, pubKey) = getReloadParams(dict: dict)
        var params: [String: AnyObject] = [:]
        params["success"] = success as AnyObject
        params["budget"] = budget as AnyObject
        params["pubkey"] = pubKey as AnyObject
        
        setTypeApplicationAndPassword(params: &params, dict: dict)
        sendMessage(dict: params)
    }
    
    func getReloadParams(dict: [String: AnyObject]) -> (Bool, Int, String) {
        let password: String? = getValue(withKey: "password")
        var budget = 0
        var pubKey = ""
        var success = false
        
        if let pass = dict["password"] as? String, pass == password {
            let savedBudget: Int? = getValue(withKey: "budget")
            let savedPubKey: String? = getValue(withKey: "pubkey")
            
            success = true
            budget = savedBudget ?? 0
            pubKey = savedPubKey ?? ""
        }
        
        return (success, budget, pubKey)
    }
    
    //KEYSEND
    func sendKeySendResponse(dict: [String: AnyObject], success: Bool) {
        var params: [String: AnyObject] = [:]
        setTypeApplicationAndPassword(params: &params, dict: dict)
        params["success"] = success as AnyObject
        
        sendMessage(dict: params)
    }
    
    func sendKeySend(_ dict: [String: AnyObject]) {
        if let dest = dict["dest"] as? String, let amt = dict["amt"] as? Int {
            let params = getParams(pubKey: dest, amount: amt)
            let canPay: DarwinBoolean = checkCanPay(amount: amt)
            if(canPay == false){
                self.sendKeySendResponse(dict: dict, success: false)
                return
            }
            API.sharedInstance.sendDirectPayment(params: params, callback: { payment in
                self.sendKeySendResponse(dict: dict, success: true)
            }, errorCallback: { _ in
                self.sendKeySendResponse(dict: dict, success: false)
            })
        }
    }
    
    //Payment
    func sendPaymentResponse(dict: [String: AnyObject], success: Bool) {
        var params: [String: AnyObject] = [:]
        setTypeApplicationAndPassword(params: &params, dict: dict)
        params["success"] = success as AnyObject
        
        sendMessage(dict: params)
    }
    
    func defaultActionResponse(dict: [String: AnyObject]) {
        var params: [String: AnyObject] = [:]
        setTypeApplicationAndPassword(params: &params, dict: dict)
        params["msg"] = "Invalid Action" as AnyObject
        
        sendMessage(dict: params)
    }
    
    func sendPayment(_ dict: [String: AnyObject]) {
        if let paymentRequest = dict["paymentRequest"] as? String {
            
            let params = ["payment_request": paymentRequest as AnyObject]
            
            let prDecoder = PaymentRequestDecoder()
            prDecoder.decodePaymentRequest(paymentRequest: paymentRequest)
            
            let amount = prDecoder.getAmount()
            
            if let amount = amount {
                let canPay: DarwinBoolean = checkCanPay(amount: amount)
                
                if (canPay == false) {
                    self.sendPaymentResponse(dict: dict, success: false)
                    return
                }
                
                API.sharedInstance.payInvoice(parameters: params, callback: { payment in
                    self.sendPaymentResponse(dict: dict, success: true)
                }, errorCallback: { _ in
                    self.sendPaymentResponse(dict: dict, success: false)
                })
            } else {
                self.sendPaymentResponse(dict: dict, success: false)
            }
        }
    }
    
    //Payment
    func sendLsatResponse(dict: [String: AnyObject], success: Bool) {
        var params: [String: AnyObject] = [:]
        setTypeApplicationAndPassword(params: &params, dict: dict)
        params["lsat"] = dict["lsat"] as AnyObject
        params["success"] = success as AnyObject
        let savedBudget: Int? = getValue(withKey: "budget")
        if let budget = savedBudget {
            params["budget"] = budget as AnyObject
            delegate?.setBudget(budget: budget)
        }
        sendMessage(dict: params)
    }
    
    func getLsatResponse(dict: [String: AnyObject], success: Bool) {
        var params: [String: AnyObject] = [:]
        setTypeApplicationAndPassword(params: &params, dict: dict)
        params["macaroon"] = dict["macaroon"] as AnyObject
        params["paymentRequest"] = dict["paymentRequest"] as AnyObject
        params["preimage"] = dict["preimage"] as AnyObject
        params["identifier"] = dict["identifier"] as AnyObject
        params["issuer"] = dict["issuer"] as AnyObject
        params["success"] = success as AnyObject
        params["status"] = dict["status"] as AnyObject
        params["paths"] = dict["paths"] as AnyObject
        sendMessage(dict: params)
    }
    
    func getPersonDataResponse(dict: [String: AnyObject], success: Bool) {
        var params: [String: AnyObject] = [:]
        setTypeApplicationAndPassword(params: &params, dict: dict)
        params["alias"] = dict["alias"] as AnyObject
        params["photoUrl"] = dict["photoUrl"] as AnyObject
        params["publicKey"] = dict["publicKey"] as AnyObject
    
        sendMessage(dict: params)
    }
    
    func updateLsatResponse(dict: [String: AnyObject], success: Bool) {
        var params: [String: AnyObject] = [:]
        setTypeApplicationAndPassword(params: &params, dict: dict)
        params["lsat"] = dict["lsat"] as AnyObject
        params["success"] = success as AnyObject
        sendMessage(dict: params)
    }
    
    func saveLSAT(_ dict: [String: AnyObject]) {
        if let paymentRequest = dict["paymentRequest"] as? String, let macaroon = dict["macaroon"] as? String, let issuer = dict["issuer"] as? String {
            
            let params = ["paymentRequest": paymentRequest as AnyObject, "macaroon": macaroon as AnyObject, "issuer": issuer as AnyObject]
            
            let prDecoder = PaymentRequestDecoder()
            prDecoder.decodePaymentRequest(paymentRequest: paymentRequest)
            
            let amount = prDecoder.getAmount()
            
            if let amount = amount {
                let canPay: DarwinBoolean = checkCanPay(amount: amount)
                if (canPay == false) {
                    self.sendLsatResponse(dict: dict, success: false)
                    return
                }
                API.sharedInstance.payLsat(parameters: params, callback: { payment in
                    var newDict = dict
                    if let lsat = payment["lsat"].string {
                        newDict["lsat"] = lsat as AnyObject
                    }
                    
                    self.sendLsatResponse(dict: newDict, success: true)
                }, errorCallback: {
                    self.sendLsatResponse(dict: dict, success: false)
                })
            }else{
                self.sendLsatResponse(dict: dict, success: false)
            }
        }
    }
    
    func sendSaveGraphResponse(dict: [String: AnyObject], success: Bool) {
        var params: [String: AnyObject] = [:]
        setTypeApplicationAndPassword(params: &params, dict: dict)
        params["lsat"] = dict["lsat"] as AnyObject
        params["success"] = success as AnyObject
        let savedBudget: Int? = getValue(withKey: "budget")
        if let budget = savedBudget {
            params["budget"] = budget as AnyObject
        }
        sendMessage(dict: params)
    }
    
    func saveGraphData(_ dict: [String: AnyObject]) {
        if let data = dict["data"] {
            if let type = data["type"] as? Int, let metaData = data["metaData"] as? AnyObject {
                
            
                let params = [
                    "type": type as AnyObject,
                    "meta_data": metaData as AnyObject
                ]
                
                API.sharedInstance.saveGraphData(parameters: params, callback: { graphData in
                    let newDict = dict
                    self.sendLsatResponse(dict: newDict, success: true)
                }, errorCallback: {
                    self.sendLsatResponse(dict: dict, success: false)
                })
            }
        }
    }
    
    //Sign Message
    func signMessageResponse(dict: [String: AnyObject], success: Bool) {
        var params: [String: AnyObject] = [:]
        setTypeApplicationAndPassword(params: &params, dict: dict)
        params["signature"] = dict["signature"] as AnyObject
        params["success"] = success as AnyObject
        sendMessage(dict: params)
    }
    
    func signMessage(_ dict: [String: AnyObject]){
        if let message = dict["message"] as? String {
            API.sharedInstance.signChallenge(challenge: message, callback: { signature in
                var newDict = dict
                if let signature = signature {
                    newDict["signature"] = signature as AnyObject
                    self.signMessageResponse(dict: newDict, success: true)
                }else {
                    self.signMessageResponse(dict: dict, success: false)
                }
            })
        }
    }
    
    func updateLsat(_ dict: [String: AnyObject]) {
        if let identifier = dict["identifier"] as? String, let status = dict["status"] as? String {
            let params = ["status": status as AnyObject]
            
            API.sharedInstance.updateLsat(identifier:identifier, parameters: params, callback: { lsat in
                var newDict = dict
                
                if let lsat = lsat["lsat"].string {
                    newDict["lsat"] = lsat as AnyObject
                }
                
                self.updateLsatResponse(dict: newDict, success: true)
            }, errorCallback: {
                self.updateLsatResponse(dict: dict, success: false)
            })
           
        }
    }
    
    func checkForExistingLsat(completion: @escaping (Int?)->()){
        API.sharedInstance.getActiveLsat(callback: { lsat in
            let newDict = self.decodeLsat(lsat: lsat, dict: [:])
            if let paymentRequest = newDict["paymentRequest"] as? String{
                let prDecoder = PaymentRequestDecoder()
                prDecoder.decodePaymentRequest(paymentRequest: paymentRequest)
                let amount = prDecoder.getAmount()
                completion(amount)
            }
        }, errorCallback: {
            print("failed to retrieve and active LSAT")
            completion(nil)
        })
    }
    
    func decodeLsat(lsat:JSON,dict:[String: AnyObject])->[String: AnyObject]{
        var newDict = dict
        if let macaroon = lsat["macaroon"].string,
            let identifier = lsat["identifier"].string,
            let preimage = lsat["preimage"].string,
            let paymentRequest = lsat["paymentRequest"].string,
            let issuer = lsat["issuer"].string,
            let status = lsat["status"].number{
            
            newDict["macaroon"] = macaroon as AnyObject
            newDict["identifier"] = identifier as AnyObject
            newDict["preimage"] = preimage as AnyObject
            newDict["paymentRequest"] = paymentRequest as AnyObject
            
            
            newDict["issuer"] = issuer as AnyObject
            newDict["status"] = status as AnyObject
            if let paths = lsat["paths"].string {
                newDict["paths"] = paths as AnyObject
            }
            else {
                newDict["paths"] = "" as AnyObject
            }
        }
        return newDict
    }
    
    func getActiveLsat(_ dict: [String: AnyObject]) {
        if let issuer = dict["issuer"] as? String {
            API.sharedInstance.getActiveLsat(issuer: issuer,callback: { lsat in
                let newDict = self.decodeLsat(lsat: lsat, dict: dict)
                self.getLsatResponse(dict: newDict, success: true)
            }, errorCallback: {
                print("failed to retrieve and active LSAT")
                self.getLsatResponse(dict: dict, success: false)
            })
        } else {
            API.sharedInstance.getActiveLsat( callback: { lsat in
                let newDict = self.decodeLsat(lsat: lsat, dict: dict)
                self.getLsatResponse(dict: newDict, success: true)
            }, errorCallback: {
                print("failed to retrieve and active LSAT")
                self.getLsatResponse(dict: dict, success: false)
            })
        }
    }
    
    func getPersonData(_ dict: [String: AnyObject]) {
        API.sharedInstance.getPersonData(callback: { person in
            var newDict = dict
            
            if let alias = person["alias"].string, let publicKey = person["publicKey"].string {
                newDict["alias"] = alias as AnyObject
                newDict["publicKey"] = publicKey as AnyObject
                
                if let photoUrl = person["photoUrl"].string {
                    newDict["photoUrl"] = photoUrl as AnyObject
                } else {
                    newDict["photoUrl"] = "" as AnyObject
                }
            }
            self.getPersonDataResponse(dict: newDict, success: true)
        }, errorCallback: {
            self.getPersonDataResponse(dict: dict, success: false)
        })
    }
    
    func getBudgetResponse(dict: [String: AnyObject], success: Bool) {
        var params: [String: AnyObject] = [:]
        setTypeApplicationAndPassword(params: &params, dict: dict)
        params["budget"] = dict["budget"] as AnyObject
        params["success"] = success as AnyObject

        sendMessage(dict: params)
    }

    func getBudget(_ dict: [String: AnyObject]) {
        let savedBudget: Int? = getValue(withKey: "budget")
        var newDict = dict
        newDict["budget"] = savedBudget as AnyObject

        self.getBudgetResponse(dict: newDict, success: true)
    }
    
    func defaultAction(_ dict: [String: AnyObject]){
        self.defaultActionResponse(dict: dict)
    }

    
    func getParams(pubKey: String, amount: Int) -> [String: AnyObject] {
        var parameters = [String : AnyObject]()
        parameters["amount"] = amount as AnyObject?
        parameters["destination_key"] = pubKey as AnyObject?
            
        return parameters
    }
    
    func saveValue(_ value: AnyObject, for key: String) {
        persistingValues[key] = value
    }
    
    func getValue<T>(withKey key: String) -> T? {
        if let value = persistingValues[key] as? T {
            return value
        }
        return nil
    }
    
    
    func checkCanPay(amount: Int) -> DarwinBoolean {
        let savedBudget: Int? = getValue(withKey: "budget")
        
        if ((savedBudget ?? 0) < amount || amount == -1) {
            return false
        }
        
        if let savedBudget = savedBudget {
            let newBudget = savedBudget - amount
            saveValue(newBudget as AnyObject, for: "budget")
            return true
        }
        
        return false
    }

}
