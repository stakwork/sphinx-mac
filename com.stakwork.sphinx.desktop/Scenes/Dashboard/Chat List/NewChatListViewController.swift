//
//  NewChatListViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NewChatListViewController: NSViewController {
    
    @IBOutlet weak var chatsCollectionView: NSCollectionView! 
    
    static func instantiate() -> NewChatListViewController {
        let viewController = StoryboardScene.Dashboard.newChatListViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
