//
//  CCSecureTextField.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class CCSecureTextField: NSSecureTextField {
    
    var onFocusChange: (Bool) -> Void = { _ in }
    
    @IBInspectable
    var color = NSColor.Sphinx.Text
    
    override func awakeFromNib() {
        super.awakeFromNib()
        customizeCaretColor()
    }
    
    func setColor(color: NSColor) {
        self.color = color
    }

    func customizeCaretColor() {
        if let fieldEditor = self.window?.fieldEditor(true, for: self) as? NSTextView {
            fieldEditor.insertionPointColor = color
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        customizeCaretColor()
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        onFocusChange(true)
        return super.resignFirstResponder()
    }
}
