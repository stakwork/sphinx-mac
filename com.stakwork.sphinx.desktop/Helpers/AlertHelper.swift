//
//  AlertHelper.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 13/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class AlertHelper {
    public static func showAlert(title: String, message: String) {
        let alert = NSAlert.init()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "Ok")
        alert.runModal()
    }
    
    public static func showTwoOptionsAlert(title: String, message: String, confirm: (() -> ())? = nil, cancel: (() -> ())? = nil) {
        let alert = NSAlert.init()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "confirm".localized)
        alert.addButton(withTitle: "cancel".localized)
        let res = alert.runModal()
        if res == NSApplication.ModalResponse.alertFirstButtonReturn {
            if let confirm = confirm {
                confirm()
            }
        } else {
            if let cancel = cancel {
                cancel()
            }
        }
    }
}
