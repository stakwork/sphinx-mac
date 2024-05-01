//
//  TribeMembersViewController.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 29/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SwiftyJSON

class TribeMembersViewController: NSViewController {

    var chat: Chat!
    var groupChatDataSource: TribeMembersDataSource?
    @IBOutlet weak var tribeMembersCollectionView: NSCollectionView!
    
    static func instantiate(chat: Chat) -> TribeMembersViewController {
        let viewController = StoryboardScene.Groups.tribeMembersViewController.instantiate()
        viewController.chat = chat
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        configureDataSource()
    }
    
    func configureDataSource() {
        if groupChatDataSource == nil {
            groupChatDataSource = TribeMembersDataSource(collectionView: tribeMembersCollectionView)
        }
        groupChatDataSource?.setDataAndReload(objects: chat)
    }
}
