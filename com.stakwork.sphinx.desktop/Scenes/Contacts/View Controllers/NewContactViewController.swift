//
//  NewContactViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 27/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol NewContactChatDelegate: AnyObject {
    func shouldReloadContacts()
}

protocol NewContactDismissDelegate: AnyObject {
    func shouldDismissView()
}

class NewContactViewController: NSViewController {
    
    weak var delegate: NewContactChatDelegate?
    weak var dismissDelegate: NewContactDismissDelegate?

    @IBOutlet weak var contactAvatarView: ChatAvatarView!
    @IBOutlet weak var fieldsTop: NSLayoutConstraint!
    @IBOutlet weak var userNameLabel: NSTextField!
    @IBOutlet weak var userNameField: NSTextField!
    @IBOutlet weak var addressLabel: NSTextField!
    @IBOutlet weak var addressField: NSTextField!
    @IBOutlet weak var addressFieldTrailing: NSLayoutConstraint!
    @IBOutlet weak var routeHintLabel: NSTextField!
    @IBOutlet weak var routeHintField: NSTextField!
    @IBOutlet weak var routeHintFieldTrailing: NSLayoutConstraint!
    @IBOutlet weak var qrButton: CustomButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var saveButtonContainer: NSView!
    @IBOutlet weak var saveButton: CustomButton!
    @IBOutlet weak var groupPinView: GroupPinView!
    
    var contact: UserContact? = nil
    var pubkey: String? = nil
    var messageBubbleHelper = NewMessageBubbleHelper()
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [saveButton])
        }
    }
    
    var saveEnabled = false {
        didSet {
            saveButtonContainer.alphaValue = saveEnabled ? 1.0 : 0.7
            saveButton.isEnabled = saveEnabled
        }
    }
    
    static func instantiate(
        delegate: NewContactChatDelegate? = nil,
        dismissDelegate: NewContactDismissDelegate? = nil,
        contact: UserContact? = nil,
        pubkey: String? = nil
    ) -> NewContactViewController {
        
        let viewController = StoryboardScene.Contacts.newContactViewController.instantiate()
        viewController.contact = contact
        viewController.delegate = delegate
        viewController.dismissDelegate = dismissDelegate
        viewController.pubkey = pubkey

        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.alphaValue = 0.0
        
        saveButtonContainer.addShadow(location: .bottom, opacity: 0.5, radius: 2.0)
        saveEnabled = false
        
        setContactInfo()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        AnimationHelper.animateViewWith(duration: 0.2, animationsBlock: {
            self.view.alphaValue = 1.0
        })
    }
    
    func setContactInfo() {
        let editing = contact != nil
        toggleViewMode(editing: editing)
        
        if let contact = contact {
            qrButton.cursor = .pointingHand
            contactAvatarView.configureSize(width: 100, height: 100, fontSize: 25)
            contactAvatarView.loadWith(contact)
            userNameLabel.stringValue = userNameLabel.stringValue.replacingOccurrences(of: " *", with: "")
            addressLabel.stringValue = addressLabel.stringValue.replacingOccurrences(of: " *", with: "")
            userNameField.stringValue = contact.getName()
            addressField.stringValue = contact.publicKey ?? ""
            routeHintField.stringValue = contact.routeHint ?? ""
            
            groupPinView.configureWith(view: view, contact: contact, delegate: self)
        } else {
            if let pubkey = pubkey {
                let (pk, rh) = (pubkey.isV2Pubkey) ? pubkey.v2PubkeyComponents : pubkey.pubkeyComponents
                addressField.stringValue = pk
                routeHintField.stringValue = rh
            }
        }
    }
    
    func toggleViewMode(editing: Bool) {
        saveButton.title = editing ? "save.upper".localized : "save.to.contacts.upper".localized
        
        contactAvatarView.isHidden = !editing
        qrButton.isHidden = !editing
        saveButtonContainer.isHidden = false
        
        addressField.isEditable = !editing
        addressField.isEnabled = !editing
        userNameField.isEditable = true
        routeHintField.isEditable = true
        
        userNameField.delegate = self
        addressField.delegate = self
        routeHintField.delegate = self
        
        addressFieldTrailing.constant = editing ? 70 : 30
        routeHintFieldTrailing.constant = editing ? 70 : 30
        fieldsTop.constant = editing ? 160 : 15
        self.view.layoutSubtreeIfNeeded()
    }
    
    @IBAction func qrButtonClicked(_ sender: Any) {
        if let address = contact?.getAddress(), !address.isEmpty {
            let shareInviteCodeVC = ShareInviteCodeViewController.instantiate(qrCodeString: address, viewMode: .PubKey)
            
            WindowsManager.sharedInstance.showVCOnRightPanelWindow(
                with: "pubkey".localized,
                identifier: "pubkey-window",
                contentVC: shareInviteCodeVC,
                shouldReplace: false
            )
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        loading = true
        if let _ = contact {
            updateProfile()
        } else if routeHintField.stringValue.isV2RouteHint {
            createV2Contact()
        } else {
            createContact()
        }
    }
    
    func updateProfile() {
        guard let contact = contact else {
            return
        }
        let nicknameDidChange = !userNameField.stringValue.isEmpty && userNameField.stringValue != contact.nickname
        let routeHint = routeHintField.stringValue
        let routeHintDidChange = routeHint != contact.routeHint
        let pin = groupPinView.getPin()
        
        if !routeHint.isEmpty && !routeHint.isRouteHint && !routeHint.isV2RouteHint {
            showErrorAlert(message: "invalid.route.hint".localized)
        } else if contact.id > 0 && (nicknameDidChange || routeHintDidChange || groupPinView.didChangePin) {
            UserContactsHelper.updateContact(
                contact: contact,
                nickname: userNameField.stringValue,
                routeHint: routeHintField.stringValue,
                pin: pin,
                callback: { success in
                    self.loading = false
                    
                    if success {
                        self.delegate?.shouldReloadContacts()
                        self.closeWindow()
                    } else {
                        self.showErrorAlert(message: "generic.error.message".localized)
                    }
                }
            )
        } else {
            loading = false
            userNameField.stringValue = contact.getName()
        }
    }
    
    func createV2Contact(){
        let nickname = userNameField.stringValue
        let pubkey = addressField.stringValue
        let routeHint = routeHintField.stringValue
        let pin = groupPinView.getPin()
        
        if !pubkey.isEmpty && !pubkey.isPubKey {
            showErrorAlert(message: "invalid.pubkey".localized)
        } else if !routeHint.isEmpty && !routeHint.isV2RouteHint {
            showErrorAlert(message: "invalid.route.hint".localized)
        } else if nickname.isEmpty || pubkey.isEmpty {
            showErrorAlert(message: "nickname.address.required".localized)
        } else {
            UserContactsHelper.createV2Contact(nickname: nickname, pubKey: pubkey, routeHint: routeHint,pin: pin, callback: { (success, _) in
                self.loading = false
                
                if success {
                    self.delegate?.shouldReloadContacts()
                    self.closeWindow()
                } else {
                    self.showErrorAlert(message: "generic.error.message".localized)
                }
            })
        }
    }

    func createContact() {
        let nickname = userNameField.stringValue
        let pubkey = addressField.stringValue
        let routeHint = routeHintField.stringValue
        let pin = groupPinView.getPin()

        if !pubkey.isEmpty && !pubkey.isPubKey {
            showErrorAlert(message: "invalid.pubkey".localized)
        } else if !routeHint.isEmpty && !routeHint.isRouteHint && !routeHint.isV2RouteHint {
            showErrorAlert(message: "invalid.route.hint".localized)
        } else if nickname.isEmpty || pubkey.isEmpty {
            showErrorAlert(message: "nickname.address.required".localized)
        } else {
            UserContactsHelper.createContact(nickname: nickname, pubKey: pubkey, routeHint: routeHint, pin: pin, callback: { (success, _) in
                self.loading = false

                if success {
                    self.delegate?.shouldReloadContacts()
                    self.closeWindow()
                } else {
                    self.showErrorAlert(message: "generic.error.message".localized)
                }
            })
        }
    }
    
    func closeWindow() {
        CoreDataManager.sharedManager.saveContext()
        if let dismissDelegate = self.dismissDelegate {
            dismissDelegate.shouldDismissView()
        } else {
            WindowsManager.sharedInstance.dismissViewFromCurrentWindow()
        }
    }

    func showErrorAlert(message: String) {
        loading = false
        messageBubbleHelper.showGenericMessageView(text: message)
    }
}

extension NewContactViewController : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField, textField == addressField || textField == routeHintField {
            if textField.stringValue.isVirtualPubKey {
                completePubkeyComponents(textField.stringValue)
            }
        }
        saveEnabled = shouldEnableSaveButton()
    }
    
    func completePubkeyComponents(_ string: String) {
        let (pubkey, routeHint) = string.pubkeyComponents
        addressField.stringValue = pubkey
        routeHintField.stringValue = routeHint
    }
    
    func shouldEnableSaveButton() -> Bool {
        if let _ = contact {
            return didChangeContact()
        }
        return userNameField.stringValue != "" && addressField.stringValue != ""
    }
    
    func didChangeContact() -> Bool {
        if let contact = contact {
            let nicknameDidChange = userNameField.stringValue != contact.nickname
            let routeHintDidChange = routeHintField.stringValue != contact.routeHint
            let pinDidChange = groupPinView.didChangePin
            return (nicknameDidChange || routeHintDidChange || pinDidChange)
        }
        return false
    }
}

extension NewContactViewController : GroupPinViewDelegate {
    func pinDidChange() {
        saveEnabled = shouldEnableSaveButton()
    }
}
