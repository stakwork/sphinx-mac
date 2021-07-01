//
//  GroupMembersViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 08/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class GroupMembersViewController: PaymentInvoiceFormViewController {
    
    var chat: Chat!
    
    @IBOutlet weak var groupMembersView: GroupMembersView!
    
    static func instantiate(childVCDelegate: ChildVCDelegate,
                            viewModel: PaymentViewModel,
                            chat: Chat,
                            delegate: ActionsDelegate?) -> GroupMembersViewController {
        
        let viewController = StoryboardScene.Groups.groupMembersViewController.instantiate()
        viewController.childVCDelegate = childVCDelegate
        viewController.paymentViewModel = viewModel
        viewController.chat = chat
        viewController.delegate = delegate
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupMembersView.configureViewWith(paymentViewModel: paymentViewModel, delegate: self)
    }
    
    override func performConfirmAction() {
        super.performConfirmAction()
        
        goToSendAmount()
    }
    
    private func goToSendAmount() {
        childVCDelegate?.shouldGoForward(paymentViewModel: paymentViewModel)
    }
    
}
