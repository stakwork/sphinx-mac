//
//  DeepLinksHandlerHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

class DeepLinksHandlerHelper {
    
    static func handleLinkQueryFrom(url: URL) {
        if !UserData.sharedInstance.isUserLogged() {
            return
        }
        
        if url.absoluteString.starts(with: API.kVideoCallServer) {
            WindowsManager.sharedInstance.showCallWindow(link: url.absoluteString)
            return
        }
        
        if let query = url.query {
            if let action = url.getLinkAction() {
                switch(action) {
                case "tribe", "tribeV2":
                    let userInfo: [String: Any] = ["tribe_link" : url.absoluteString]
                    NotificationCenter.default.post(name: .onJoinTribeClick, object: nil, userInfo: userInfo)
                    break
                case "auth":
                    let userInfo: [String: Any] = ["query" : query]
                    NotificationCenter.default.post(name: .onAuthDeepLink, object: nil, userInfo: userInfo)
                    break
                case "person":
                    let userInfo: [String: Any] = ["query" : query]
                    NotificationCenter.default.post(name: .onPersonDeepLink, object: nil, userInfo: userInfo)
                    break
                case "save":
                    let userInfo: [String: Any] = ["query" : query]
                    NotificationCenter.default.post(name: .onSaveProfileDeepLink, object: nil, userInfo: userInfo)
                    break
                case "challenge":
                    let userInfo: [String: Any] = ["query" : query]
                    NotificationCenter.default.post(name: .onStakworkAuthDeepLink, object: nil, userInfo: userInfo)
                case "redeem_sats":
                    let userInfo: [String: Any] = ["query" : query]
                    NotificationCenter.default.post(name: .onRedeemSatsDeepLink, object: nil, userInfo: userInfo)
                case "invoice":
                    let userInfo: [String: Any] = ["query" : query]
                    NotificationCenter.default.post(name: .onInvoiceDeepLink, object: nil, userInfo: userInfo)
                case "share_content":
                    let userInfo: [String: Any] = ["query" : query]
                    NotificationCenter.default.post(name: .onShareContentDeeplink, object: nil, userInfo: userInfo)
                case "share_contact":
                    let userInfo: [String: Any] = ["query" : query]
                    NotificationCenter.default.post(name: .onShareContactDeeplink, object: nil, userInfo: userInfo)
                case "call":
                    if let link = url.getCallLink() {
                        WindowsManager.sharedInstance.showCallWindow(link: link)
                    }
                default:
                    break
                }
            }
        }
    }
}
