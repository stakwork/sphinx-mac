//
//  ContactViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class ContactViewController: NSViewController {
    
    var contact : UserContact!
    
    @IBOutlet weak var contactAvatarView: ChatAvatarView!
    @IBOutlet weak var contactName: NSTextField!
    @IBOutlet weak var contactPubKey: NSTextField!
    @IBOutlet weak var copyButton: CustomButton!
    @IBOutlet weak var qrButton: CustomButton!
    
    static func instantiate(contact: UserContact) -> ContactViewController {
        let viewController = StoryboardScene.Dashboard.contactViewController.instantiate()
        viewController.contact = contact
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        copyButton.cursor = .pointingHand
        qrButton.cursor = .pointingHand
        contactAvatarView.configureSize(width: 100, height: 100, fontSize: 25)
        contactAvatarView.loadWith(contact)
        contactName.stringValue = contact.getName()
        contactPubKey.stringValue = contact.publicKey ?? ""
    }
    
    @IBAction func qrCodeButtonClicked(_ sender: Any) {
        let pubKey = contact.publicKey ?? ""
        let shareInviteCodeVC = ShareInviteCodeViewController.instantiate(qrCodeString: pubKey, viewMode: .PubKey)
        self.view.window?.replaceContentBy(vc: shareInviteCodeVC, with: CGSize(width: 400, height: 600))
    }
    
    @IBAction func copyButtonClicked(_ sender: Any) {
        let pubKey = contact.publicKey ?? ""
        ClipboardHelper.copyToClipboard(text: pubKey, message: "pubkey.copied.clipboard".localized, bubbleContainer: self.view)
    }
}
