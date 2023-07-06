//
//  DashboardSplittedViewController.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 15/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol DashboardVCDelegate: AnyObject {
    func didClickOnChatRow(chatId: Int?, contactId: Int?)
    func didReloadDashboard()
    func shouldShowRestoreModal(with progress: Int, messagesStartProgress: Int)
    func shouldHideRetoreModal()
    func shouldShowFullMediaFor(message: TransactionMessage)
    func shouldToggleLeftView(show: Bool?)
}

class DashboardSplittedViewController: NSViewController {
    
    weak var delegate: DashboardVCDelegate?
    
    var chatViewModel: ChatViewModel! = nil
    var chatListViewModel: ChatListViewModel! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setDataModels(
        chatListViewModel: ChatListViewModel,
        chatViewModel: ChatViewModel
    ) {
        self.chatListViewModel = chatListViewModel
        self.chatViewModel = chatViewModel
    }
    
}
