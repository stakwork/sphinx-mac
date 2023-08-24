//
//  AlertHelper.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 13/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class AlertHelper {
    public static func showAlert(
        title: String,
        message: String,
        confirmLabel: String? = nil,
        confirm: (() -> ())? = nil
    ) {
        let alert = NSAlert.init()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: confirmLabel ?? "Ok")
        
        let res = alert.runModal()
        if res == NSApplication.ModalResponse.alertFirstButtonReturn {
            if let confirm = confirm {
                confirm()
            }
        }
    }
    
    public static func showTwoOptionsAlert(
        title: String,
        message: String,
        confirm: (() -> ())? = nil,
        cancel: (() -> ())? = nil,
        confirmLabel: String? = nil,
        cancelLabel: String? = nil
    ) {
        let alert = NSAlert.init()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: confirmLabel ?? "confirm".localized)
        alert.addButton(withTitle: cancelLabel ?? "cancel".localized)
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
    
    class func showOptionsPopup(
        title: String,
        message: String,
        options: [String],
        callbacks: [() -> ()]
    ) {
        
        let alert = NSAlert.init()
        alert.messageText = title
        alert.informativeText = message
        
        for x in 0..<options.count {
            let option = options[x]
            
            alert.addButton(withTitle: option)
        }
        
        let res = alert.runModal()
        if res == NSApplication.ModalResponse.alertFirstButtonReturn {
            callbacks[0]()
        } else if res == NSApplication.ModalResponse.alertSecondButtonReturn {
            callbacks[1]()
        } else {
            callbacks[2]()
        }
    }
    
    class func showPromptAlert(
        title: String,
        message: String,
        textFieldText: String? = nil,
        confirm: ((String?) -> ())? = nil,
        cancel: (() -> ())? = nil
    ){
        let alert = NSAlert.init()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "confirm".localized)
        alert.addButton(withTitle: "cancel".localized)
        
        let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        txt.stringValue = textFieldText ?? ""
        alert.accessoryView = txt
        
        let res = alert.runModal()
        
        if res == NSApplication.ModalResponse.alertFirstButtonReturn {
            if let confirm = confirm {
                confirm(
                    txt.stringValue
                )
            }
        } else {
            if let cancel = cancel {
                cancel()
            }
        }
    }
}
