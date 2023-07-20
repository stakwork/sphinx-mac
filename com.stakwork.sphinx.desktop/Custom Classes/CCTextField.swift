//
//  CCTextField.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 12/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CCTextField: NSTextField {
    
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
    
    func setSelectionColor(color: NSColor) {
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
