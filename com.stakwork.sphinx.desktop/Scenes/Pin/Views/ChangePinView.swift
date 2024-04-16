//
//  ChangePinView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 16/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ChangePinView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var oldPinFieldView: SignupSecureFieldView!
    @IBOutlet weak var newPinFieldView: SignupSecureFieldView!
    @IBOutlet weak var confirmNewPinFieldView: SignupSecureFieldView!
    @IBOutlet weak var confirmButtonView: SignupButtonView!
    
    var newMessageBubbleHelper = NewMessageBubbleHelper()
    
    var doneCompletion: ((String) -> ())? = nil
    
    var mode = ChangePinViewController.ChangePinMode.ChangeStandard
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        configureView()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        configureView()
    }
    
    func configureView() {
        confirmButtonView.configureWith(title: "confirm".localized, icon: "", tag: -1, delegate: self)
        confirmButtonView.buttonDisabled = true
        
        oldPinFieldView.configureWith(placeHolder: "current.pin".localized, label: "current.pin".localized, backgroundColor: NSColor.Sphinx.PinFieldBackground, color: NSColor.Sphinx.Text, placeHolderColor: NSColor.Sphinx.SecondaryText, field: .OldPIN, delegate: self)
        newPinFieldView.configureWith(placeHolder: "new.pin".localized, label: "new.pin".localized, backgroundColor: NSColor.Sphinx.PinFieldBackground, color: NSColor.Sphinx.Text, placeHolderColor: NSColor.Sphinx.SecondaryText, field: .PIN, delegate: self)
        confirmNewPinFieldView.configureWith(placeHolder: "confirm.new.pin".localized, label: "confirm.new.pin".localized, backgroundColor: NSColor.Sphinx.PinFieldBackground, color: NSColor.Sphinx.Text, placeHolderColor: NSColor.Sphinx.SecondaryText, field: .ConfirmPIN, delegate: self)
    }
    
    func set(mode: ChangePinViewController.ChangePinMode) {
        self.mode = mode
        
        if mode == .SetPrivacy {
            oldPinFieldView.getTextField().isEnabled = false
            oldPinFieldView.alphaValue = 0.3
        }
    }
}

extension ChangePinView : SignupButtonViewDelegate {
    func didClickButton(tag: Int) {
        let pin = newPinFieldView.getFieldValue()
        doneCompletion?(pin)
    }
}

extension ChangePinView : SignupFieldViewDelegate {
    func didChangeText(text: String) {
        confirmButtonView.buttonDisabled = !isValid()
        
        if pinDoNotMatch() {
            newMessageBubbleHelper.showGenericMessageView(text: "pins.do.not.match".localized, delay: 3, textColor: NSColor.white, backColor: NSColor.Sphinx.BadgeRed, backAlpha: 1.0)
        }
    }
    
    func isValid() -> Bool {
        if mode == .SetPrivacy {
            return newPinFieldView.getFieldValue().length == 6 &&
                   confirmNewPinFieldView.getFieldValue().length == 6 &&
                   newPinFieldView.getFieldValue() == confirmNewPinFieldView.getFieldValue()
        }
        
        return oldPinFieldView.getFieldValue().length == 6 &&
               newPinFieldView.getFieldValue().length == 6 &&
               confirmNewPinFieldView.getFieldValue().length == 6 &&
               newPinFieldView.getFieldValue() == confirmNewPinFieldView.getFieldValue() &&
               oldPinFieldView.getFieldValue() == getChangingPin() &&
               newPinFieldView.getFieldValue() != getChangingPin()
    }
    
    func pinDoNotMatch() -> Bool {
        return newPinFieldView.getFieldValue().length == 6 && confirmNewPinFieldView.getFieldValue().length == 6 && newPinFieldView.getFieldValue() != confirmNewPinFieldView.getFieldValue()
    }
    
    func getChangingPin() -> String? {
        if mode == .ChangeStandard {
            return UserData.sharedInstance.getAppPin()
        } else {
            return UserData.sharedInstance.getPrivacyPin()
        }
    }
    
    func didUseTab(field: Int) {
        confirmButtonView.buttonDisabled = !isValid()
        
        let field = NamePinView.Fields(rawValue: field)
        switch (field) {
        case .OldPIN:
            self.window?.makeFirstResponder(newPinFieldView.getTextField())
            break
        case .PIN:
            self.window?.makeFirstResponder(confirmNewPinFieldView.getTextField())
            break
        default:
            if mode == .SetPrivacy {
                self.window?.makeFirstResponder(newPinFieldView.getTextField())
            } else {
                self.window?.makeFirstResponder(oldPinFieldView.getTextField())
            }
            break
        }
    }
}
