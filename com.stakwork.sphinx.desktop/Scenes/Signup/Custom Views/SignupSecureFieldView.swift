//
//  SignupSecureFieldView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class SignupSecureFieldView: SignupCommonFieldView {
    
    let pinLength = 6
    
    func configureWith(placeHolder: String,
                       label: String,
                       backgroundColor: NSColor = NSColor(hex: "#101317"),
                       color: NSColor = NSColor.white,
                       placeHolderColor: NSColor = NSColor(hex: "#3B4755"),
                       field: NamePinView.Fields,
                       delegate: SignupFieldViewDelegate) {
        
        self.field = field
        self.delegate = delegate
        
        fieldBox.fillColor = backgroundColor
        
        topLabel.stringValue = label
        topLabel.alphaValue = 0.0
        textField.setPlaceHolder(color: placeHolderColor, font: NSFont(name: "Roboto-Regular", size: 14.0)!, string: placeHolder)
        //textField.color = color
        textField.textColor = color 
        textField.delegate = self 
//        textField.onFocusChange = { active in
//            super.toggleActiveState(active)
//        }
        textField.window?.makeFirstResponder(textField)
    }
}

extension SignupSecureFieldView {
    override func controlTextDidChange(_ obj: Notification) {
        topLabel.alphaValue = textField.stringValue.isEmpty ? 0.0 : 1.0
        
        let pinString = textField.stringValue
        
        if pinString.length > 6 || Int(pinString) == nil{
            textField.stringValue = String(pinString.dropLast())
        }
        delegate?.didChangeText?(text: textField.stringValue)
        
        if textField.stringValue.length == pinLength {
            DelayPerformedHelper.performAfterDelay(seconds: 0.2, completion: {
                self.delegate?.didConfirmPin?(text: self.textField.stringValue)
            })
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(NSResponder.insertTab(_:))) {
            self.delegate?.didUseTab?(field: field.rawValue)
            return true
        }
        return false
    }
}
