//
//  ConnectivityHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 08/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Alamofire
import SystemConfiguration

struct ConnectivityHelper {
    static let sharedInstance = NetworkReachabilityManager()!

    static var isConnectedToInternet: Bool {
        return self.sharedInstance.isReachable && ConnectivityHelper.isConnected()
    }
    
    static func isConnected() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
}
