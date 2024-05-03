//
//  APIWalletExtension.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    func getWalletBalance(callback: @escaping BalanceCallback, errorCallback: @escaping EmptyCallback){
        guard let request = getURLRequest(route: "/balance", method: "GET") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        let data = JSON(response).dictionaryValue
                        if let balance = data["balance"]?.intValue {
                            callback(balance)
                            return
                        }
                    }
                }
                errorCallback()
            case .failure(let error):
                print(error)
                errorCallback()
            }
        }
    }
    
    func getWalletLocalAndRemote(callback: @escaping BalancesCallback, errorCallback: @escaping EmptyCallback){
        guard let request = getURLRequest(route: "/balance/all", method: "GET") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"], success {
                        let data = JSON(response).dictionaryValue
                        if let localBalance = data["local_balance"]?.intValue, let remoteBalance = data["remote_balance"]?.intValue {
                            callback(localBalance, remoteBalance)
                            return
                        }
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
}
