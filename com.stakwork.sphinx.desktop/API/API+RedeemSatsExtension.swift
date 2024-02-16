//
//  API+RedeemSatsExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 13/07/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension API {
    func redeemSats(url: String, params: [String: AnyObject], callback: @escaping EmptyCallback, errorCallback: @escaping EmptyCallback){
        guard let request = createRequest(url, params: params as NSDictionary, method: "POST") else {
            errorCallback()
            return
        }
        
        AF.request(request).responseJSON { (response) in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, success {
                        callback()
                        return
                    }
                }
                errorCallback()
            case .failure(_):
                errorCallback()
            }
        }
    }
}
