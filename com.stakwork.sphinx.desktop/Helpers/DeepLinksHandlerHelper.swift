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
        if let _ = url.query, UserData.sharedInstance.isUserLogged() {
            if let action = url.getLinkAction() {
                switch(action) {
                case "tribe":
                    let userInfo: [String: Any] = ["tribe_link" : url.absoluteString]
                    NotificationCenter.default.post(name: .onJoinTribeClick, object: nil, userInfo: userInfo)
                    break
                default:
                    break
                }
            }
        }
    }
}
