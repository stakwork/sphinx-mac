//
//  Notification.Name.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let onBalanceDidChange = Notification.Name("onBalanceDidChange")
    static let shouldUpdateDashboard = Notification.Name("shouldUpdateDashboard")
    static let shouldReadChat = Notification.Name("shouldReadChat")
    static let shouldResetChat = Notification.Name("shouldResetChat")
    static let shouldReloadViews = Notification.Name("shouldReloadViews")
    static let shouldReloadChatsList = Notification.Name("shouldReloadChatsList")
    static let onPubKeyClick = Notification.Name("onPubKeyClick")
    static let onJoinTribeClick = Notification.Name("onJoinTribeClick")
    static let chatNotificationClicked = Notification.Name("chatNotificationClicked")
    static let onConnectionStatusChanged = Notification.Name.init("onConnectionStatusChanged")
    static let screenIsLocked = Notification.Name.init("com.apple.screenIsLocked")
    static let screenIsUnlocked = Notification.Name.init("com.apple.screenIsUnlocked")
    static let onTribeImageChanged = Notification.Name("onTribeImageChanged")
    static let onInterfaceThemeChanged = Notification.Name("AppleInterfaceThemeChangedNotification")
}
