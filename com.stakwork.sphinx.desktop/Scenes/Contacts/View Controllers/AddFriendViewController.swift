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
    
    static func instantiate(
        delegate: NewContactChatDelegate? = nil
    ) -> AddFriendViewController {
        let viewController = StoryboardScene.Contacts.addFriendViewController.instantiate()
        viewController.delegate = delegate
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func newToSphinxButtonClicked(_ sender: Any) {
        let inviteVC = NewInviteViewController.instantiate(delegate: self.delegate)
        advanceTo(vc: inviteVC)
    }
    
    @IBAction func alreadyOnSphinxButtonClicked(_ sender: Any) {
        let contactVC = NewContactViewController.instantiate(delegate: self.delegate)
        advanceTo(vc: contactVC)
    }
    
    func advanceTo(vc: NSViewController) {
        AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
            self.view.alphaValue = 0.0
        }, completion: {
            self.view.window?.replaceContentBy(vc: vc)
        })
    }
}
