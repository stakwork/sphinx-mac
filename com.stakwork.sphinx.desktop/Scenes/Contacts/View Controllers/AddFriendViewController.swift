//
//  AddFriendViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class AddFriendViewController: NSViewController {
    
    weak var delegate: NewContactChatDelegate?
    weak var dismissDelegate: NewContactDismissDelegate?
    
    static func instantiate(
        delegate: NewContactChatDelegate? = nil,
        dismissDelegate: NewContactDismissDelegate? = nil
    ) -> AddFriendViewController {
        let viewController = StoryboardScene.Contacts.addFriendViewController.instantiate()
        viewController.delegate = delegate
        viewController.dismissDelegate = dismissDelegate
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func newToSphinxButtonClicked(_ sender: Any) {
        let inviteVC = NewInviteViewController.instantiate(
            delegate: self.delegate,
            dismissDelegate: self.dismissDelegate
        )
        
        advanceTo(
            vc: inviteVC,
            identifier: "new-invite-window",
            height: 500
        )
    }
    
    @IBAction func alreadyOnSphinxButtonClicked(_ sender: Any) {
        let contactVC = NewContactViewController.instantiate(
            delegate: self.delegate,
            dismissDelegate: self.dismissDelegate
        )
        
        advanceTo(
            vc: contactVC,
            identifier: "new-contact-window"
        )
    }
    
    func advanceTo(
        vc: NSViewController,
        identifier: String,
        height: CGFloat? = nil
    ) {
        WindowsManager.sharedInstance.showOnCurrentWindow(
            with: "Contact".localized,
            identifier: identifier,
            contentVC: vc,
            hideDivider: true,
            hideBackButton: false,
            replacingVC: true,
            height: height,
            backHandler: WindowsManager.sharedInstance.backToAddFriend
        )
    }
}
