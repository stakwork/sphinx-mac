//
//  NamePinView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SwiftyJSON

class NamePinView: NSView, LoadableNib {
    
    weak var delegate: WelcomeEmptyViewDelegate?

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var nameField: SignupFieldView!
    @IBOutlet weak var pinField: SignupSecureFieldView!
    @IBOutlet weak var confirmPinField: SignupSecureFieldView!
    @IBOutlet weak var continueButton: SignupButtonView!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    let messageBubbleHelper = NewMessageBubbleHelper()
    let userData = UserData.sharedInstance
    
    var isSphinxV2 = false
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [continueButton.getButton()])
        }
    }
    
    public enum Fields: Int {
        case Code
        case Name
        case PIN
        case ConfirmPIN
        case OldPIN
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    init(
        frame frameRect: NSRect,
        delegate: WelcomeEmptyViewDelegate,
        isSphinxV2: Bool = false
    ) {
        super.init(frame: frameRect)
        
        self.delegate = delegate
        self.isSphinxV2 = isSphinxV2
        
        loadViewFromNib()
        configureView()
    }
    
    func setInitialFirstResponder() {
        window?.initialFirstResponder = nameField.getTextField()
    }
    
    func configureView() {
        continueButton.configureWith(title: "continue".localized.capitalized, icon: "", tag: -1, delegate: self)
        continueButton.setSignupColors()
        continueButton.buttonDisabled = true
        
        nameField.configureWith(placeHolder: "set.nickname".localized, placeHolderColor: NSColor(hex: "#3B4755"), label: "Nickname", textColor: NSColor.white, backgroundColor: NSColor(hex: "#101317"), field: .Name, delegate: self)
        pinField.configureWith(placeHolder: "set.pin".localized, label: "set.pin".localized, field: .PIN, delegate: self)
        confirmPinField.configureWith(placeHolder: "confirm.pin".localized, label: "confirm.pin".localized, field: .ConfirmPIN, delegate: self)
        
        if let owner = UserContact.getOwner() {
            nameField.set(fieldValue: owner.nickname ?? "")
            pinField.set(fieldValue: userData.getAppPin() ?? "")
            confirmPinField.set(fieldValue: userData.getAppPin() ?? "")
            
            continueButton.buttonDisabled = !isValid()
        }
    }
    
    func getNickname() -> String {
        return nameField.getFieldValue()
    }
}

extension NamePinView : SignupButtonViewDelegate {
    func didClickButton(tag: Int) {
        if !nameField.getFieldValue().isEmpty {
            loading = true
            
            if isSphinxV2,
                let selfContact = SphinxOnionManager.sharedInstance.pendingContact,
                selfContact.isOwner == true
            {
                let nickname = nameField.getFieldValue()
                selfContact.nickname = nickname
                self.goToProfilePictureView()
            } else if !isSphinxV2 {
                API.sharedInstance.getContacts(callback: {(contacts, _, _, _) -> () in
                    self.insertAndUpdateOwner(contacts: contacts)
                })
            } else {
                showError()
            }
        } else {
            showError()
        }
    }
    
    func insertAndUpdateOwner(contacts: [JSON]) {
        let nickname = nameField.getFieldValue()
        
        UserContactsHelper.insertContacts(contacts: contacts)
        UserData.sharedInstance.saveNewNodeOnKeychain()
        
        let id = UserData.sharedInstance.getUserId()
        let parameters = ["alias" : nickname as AnyObject]
        
        API.sharedInstance.updateUser(id: id, params: parameters, callback: { contact in
            let _ = UserContactsHelper.insertContact(contact: contact)
            self.goToProfilePictureView()
        }, errorCallback: {
            self.showError()
        })
    }
    
    func showError() {
        loading = false
        messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized)
    }
    
    func goToProfilePictureView() {
        loading = false
        UserData.sharedInstance.save(pin: pinField.getFieldValue())
        SignupHelper.step = SignupHelper.SignupStep.PINNameSet.rawValue
        delegate?.shouldContinueTo?(mode: WelcomeLightningViewController.FormViewMode.Image.rawValue)
    }
    
    func isValid() -> Bool {
        return !nameField.getFieldValue().isEmpty && pinField.getFieldValue().length == 6 && confirmPinField.getFieldValue().length == 6 && pinField.getFieldValue() == confirmPinField.getFieldValue()
    }
    
    func pinDoNotMatch() -> Bool {
        return !nameField.getFieldValue().isEmpty && pinField.getFieldValue().length == 6 && confirmPinField.getFieldValue().length == 6 && pinField.getFieldValue() != confirmPinField.getFieldValue()
    }
}

extension NamePinView : SignupFieldViewDelegate {
    func didChangeText(text: String) {
        continueButton.buttonDisabled = !isValid()
        
        if pinDoNotMatch() {
            messageBubbleHelper.showGenericMessageView(text: "pins.do.not.match".localized, delay: 3, textColor: NSColor.white, backColor: NSColor.Sphinx.BadgeRed, backAlpha: 1.0)
        }
    }
    
    func didUseTab(field: Int) {
        let field = NamePinView.Fields(rawValue: field)
        switch (field) {
        case .Name:
            self.window?.makeFirstResponder(pinField.getTextField())
            break
        case .PIN:
            self.window?.makeFirstResponder(confirmPinField.getTextField())
            break
        default:
            self.window?.makeFirstResponder(nameField.getTextField())
            break
        }
    }
}
