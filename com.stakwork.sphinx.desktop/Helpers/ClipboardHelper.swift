//
//  ClipboardHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class ClipboardHelper {
    
    public static func copyToClipboard(text: String, message: String? = "text.copied.clipboard".localized, bubbleContainer: NSView? = nil) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(text, forType: .string)
        
        if let message = message {
            NewMessageBubbleHelper().showGenericMessageView(text: message, in: bubbleContainer)
        }
    }
}
