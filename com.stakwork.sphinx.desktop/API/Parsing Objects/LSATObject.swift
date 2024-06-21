//
//  LSATObject.swift
//  Sphinx
//
//  Created by James Carucci on 5/2/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import ObjectMapper


class LSATObject : Mappable {
    var issuer : String?
    var macaroon: String?
    var identifier: String?
    var paymentRequest:String?
    var preImage:String?
    
    required convenience init(map: Map) {
        self.init()
    }
    

    func mapping(map: Map) {
        issuer        <- map["issuer"]
        macaroon   <- map["macaroon"]
        identifier        <- map["identifier"]
        preImage        <- map["preimage"]
        paymentRequest        <- map["paymentRequest"]
    }
    
}
