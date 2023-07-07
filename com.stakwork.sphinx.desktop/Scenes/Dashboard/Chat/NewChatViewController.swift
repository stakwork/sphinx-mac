//
//  NewChatViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 07/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NewChatViewController: DashboardSplittedViewController {
    
    @IBOutlet weak var chatTopView: ChatTopView!
    
    var contact: UserContact?
    var chat: Chat?
    
    static func instantiate(
        contact: UserContact? = nil,
        chat: Chat? = nil,
        delegate: DashboardVCDelegate?
    ) -> NewChatViewController {
        
        let viewController = StoryboardScene.Dashboard.newChatViewController.instantiate()
        
        viewController.chat = chat
        viewController.contact = contact
        viewController.delegate = delegate
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
