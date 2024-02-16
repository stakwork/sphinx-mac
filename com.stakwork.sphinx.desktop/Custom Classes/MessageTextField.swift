//
//  LinkHandlerTextField.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 03/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class MessageTextField: CCTextField, NSTextViewDelegate {
    func textViewDidChangeSelection(_ notification: Notification) {
        if let textView = notification.object as? NSTextView {
            textView.selectedTextAttributes = [NSAttributedString.Key.backgroundColor : color]
        }
    }
}
