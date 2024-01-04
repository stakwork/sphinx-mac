//
//  SignupCommonFieldView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 15/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

@objc protocol SignupFieldViewDelegate: AnyObject {
    @objc optional func didChangeText(text: String)
    @objc optional func didUseTab(field: Int)
    @objc optional func didConfirmPin(text: String)
}

class SignupCommonFieldView: NSView, LoadableNib {
    
    weak var delegate: SignupFieldViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var topLabel: NSTextField!
    @IBOutlet weak var fieldBox: NSBox!
    @IBOutlet weak var textField: NSSecureTextField!
    
    var field: NamePinView.Fields = .Name
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    func getFieldValue() -> String {
        return textField.stringValue
    }
    
    func getTextField() -> NSTextField {
        return textField
    }
    
    func set(fieldValue: String) {
        textField.stringValue = fieldValue
        topLabel.alphaValue = textField.stringValue.isEmpty ? 0.0 : 1.0
    }
}

extension SignupCommonFieldView : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) { }
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        toggleActiveState(true)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        toggleActiveState(false)
    }
    
    func toggleActiveState(_ active: Bool) {
        fieldBox.borderType = active ? .lineBorder : .noBorder
        fieldBox.borderWidth = active ? 2 : 0
        fieldBox.borderColor = NSColor.Sphinx.ReceivedIcon
        
        topLabel.textColor = active ? NSColor.Sphinx.ReceivedIcon : NSColor.Sphinx.SecondaryText
    }
}
