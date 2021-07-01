//
//  NewInviteViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class NewInviteViewController: NSViewController {
    
    weak var delegate: NewContactChatDelegate?
    
    @IBOutlet weak var nicknameField: NSTextField!
    @IBOutlet var messageTextView: PlaceHolderTextView!
    @IBOutlet weak var estimatedCostLabel: NSTextField!
    @IBOutlet weak var estimatedCostContainer: NSView!
    @IBOutlet weak var saveButtonContainer: NSView!
    @IBOutlet weak var saveButton: CustomButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    var contactsService : ContactsService!
    let walletBalanceService = WalletBalanceService()
    
    static func instantiate(contactsService: ContactsService, delegate: NewContactChatDelegate? = nil) -> NewInviteViewController {
        let viewController = StoryboardScene.Contacts.newInviteViewController.instantiate()
        viewController.contactsService = contactsService
        viewController.delegate = delegate
        return viewController
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [saveButton])
        }
    }
    
    var saveEnabled = false {
        didSet {
            saveButtonContainer.alphaValue = saveEnabled ? 1.0 : 0.7
            saveButton.isEnabled = saveEnabled
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.estimatedCostContainer.alphaValue = 0.0
        self.view.alphaValue = 0.0
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        configureView()
        
        AnimationHelper.animateViewWith(duration: 0.2, animationsBlock: {
            self.view.alphaValue = 1.0
        })
    }
    
    func configureView() {
        saveEnabled = false
        
        nicknameField.delegate = self
        
        messageTextView.isEditable = true
        messageTextView.setPlaceHolder(color: NSColor.Sphinx.PlaceholderText, font: NSFont(name: "Roboto-Regular", size: 17.0)!, string: "welcome.to.sphinx".localized, alignment: .center)
        messageTextView.font = NSFont(name: "Roboto-Regular", size: 17.0)!
        messageTextView.alignment = .center
        
        getLowestPrice()
    }
    
    func getLowestPrice() {
        API.sharedInstance.getLowestPrice(callback: { price in
            self.configurePriceContainer(lowestPrice: Int(price))
        }, errorCallback: { })
    }
    
    func configurePriceContainer(lowestPrice: Int) {
        let localBalance = walletBalanceService.balance
        if localBalance > lowestPrice && lowestPrice > 0 {
            estimatedCostLabel.stringValue = lowestPrice.formattedWithSeparator
            
            AnimationHelper.animateViewWith(duration: 0.2, animationsBlock: {
                self.estimatedCostContainer.alphaValue = 1.0
            })
        } else {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "invite.more.sats".localized)
        }
    }
    
    @IBAction func createInvitationButtonClicked(_ sender: Any) {
        let nickname = nicknameField.stringValue
        let message = messageTextView.string.isEmpty ? "welcome.to.sphinx".localized : messageTextView.string
        
        if !nickname.isEmpty && !message.isEmpty {
            var parameters = [String : AnyObject]()
            parameters["nickname"] = nickname as AnyObject?
            parameters["welcome_message"] = message as AnyObject?
            
            loading = true
            
            API.sharedInstance.createUserInvite(parameters: parameters, callback: { contact in
                self.contactsService.insertContact(contact: contact)
                
                if let invite = contact["invite"].dictionary, let inviteString = invite["invite_string"]?.string, !inviteString.isEmpty {
                    self.delegate?.shouldReloadContacts()
                    self.view.window?.close()
                }
            }, errorCallback: {
                self.loading = false
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            })
        }
    }
}

extension NewInviteViewController : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        saveEnabled = shouldEnableSaveButton()
    }
    
    func shouldEnableSaveButton() -> Bool {
        return nicknameField.stringValue != ""
    }
}
