//
//  DashboardSplittedViewController.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 15/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol DashboardVCDelegate: AnyObject {
    func didClickOnChatRow(object: ChatListCommonObject)
    func didReloadDashboard()
    func shouldReloadChatList()
    func shouldShowFullMediaFor(message: TransactionMessage)
    func shouldToggleLeftView(show: Bool?)
}

class DashboardSplittedViewController: NSViewController {
    
    weak var delegate: DashboardVCDelegate?
    
    var contactsService : ContactsService! = nil
    var chatViewModel: ChatViewModel! = nil
    var chatListViewModel: ChatListViewModel! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setDataModels(contactsService: ContactsService, chatListViewModel: ChatListViewModel, chatViewModel: ChatViewModel) {
        self.contactsService = contactsService
        self.chatListViewModel = chatListViewModel
        self.chatViewModel = chatViewModel
    }
    
}
