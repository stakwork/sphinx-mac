//
//  VoIPRequestMessage.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 03/03/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

import ObjectMapper

class VoIPRequestMessage : Mappable {
    var recurring:Bool = false
    var cron: String?
    var link: String?

    required convenience init(map: Map) {
        self.init()
    }
    
    static func getFromString(_ string: String) -> VoIPRequestMessage? {
        if string.starts(with: "call::") {
            return VoIPRequestMessage(JSONString: string.replacingOccurrences(of: "call::", with: ""))
        } else {
            return VoIPRequestMessage(JSONString: string)
        }
    }

    func mapping(map: Map) {
        link        <- map["link"]
        recurring   <- map["recurring"]
        cron        <- map["cron"]
    }
    
    func getCallLinkMessage() -> String? {
        if let json = self.toJSONString() {
            return "call::\(json)"
        }
        return nil
    }
}
