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
        
        advanceTo(vc: inviteVC, height: 500)
    }
    
    @IBAction func alreadyOnSphinxButtonClicked(_ sender: Any) {
        let contactVC = NewContactViewController.instantiate(
            delegate: self.delegate,
            dismissDelegate: self.dismissDelegate
        )
        
        advanceTo(vc: contactVC)
    }
    
    func advanceTo(
        vc: NSViewController,
        height: CGFloat? = nil
    ) {
        AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
            self.view.alphaValue = 0.0
        }, completion: {
            WindowsManager
                .sharedInstance
                .showOnCurrentWindow(
                    with: "Contact".localized,
                    identifier: "new-contact-window",
                    contentVC: vc,
                    hideDivider: true,
                    hideBackButton: false,
                    height: height,
                    backHandler: WindowsManager.sharedInstance.backToAddFriend
                )
        })
    }
}
