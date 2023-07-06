//
//  ChatListViewControllerExtension.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

public let balanceDidChange = "balanceDidChange"

extension ChatListViewController {
    
    func configureHeaderAndBottomBar() {
        NSAppearance.current = view.effectiveAppearance
        
        searchBarContainer.addShadow(location: VerticalLocation.bottom, color: NSColor.black, opacity: 0.2, radius: 5.0)
        bottomBar.addShadow(location: VerticalLocation.top, color: NSColor.black, opacity: 0.2, radius: 5.0)

        searchFieldContainer.wantsLayer = true
        searchFieldContainer.layer?.cornerRadius = searchFieldContainer.frame.height / 2
    }
    
    func listenForNotifications() {
        healthCheckView.listenForEvents()
        balanceLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleBalanceClick)))
        
        NotificationCenter.default.addObserver(
            forName: .onBalanceDidChange,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] (n: Notification) in
                self?.updateBalance()
        }
    }
    
    func updateBalance() {
        balanceUnitLabel.stringValue = "sat"
        walletBalanceService.updateBalance(labels: [balanceLabel])
    }
    
    func resetSearchField() {
        searchField?.stringValue = ""
        
        NotificationCenter.default.post(
            name: NSControl.textDidChangeNotification,
            object: searchField
        )
    }
    
    @objc func handleBalanceClick(){
        let vc = ChoosePaymentModeVC.instantiate(delegate: self)
        
        WindowsManager.sharedInstance.showContactWindow(
            vc: vc,
            window: view.window,
            title: "Manage Payments",
            identifier: "invoice-management-window",
            size: CGSize(width: 414, height: 350)
        )
        
    }
    
}

extension ChatListViewController : ChildVCDelegate,ActionsDelegate,ChoosePaymentModeVCDelegate{
    func handleReceiveClick() {
        let vc = CreateInvoiceViewController.instantiate(
            childVCDelegate: self,
            viewModel: PaymentViewModel(mode: .Request),
            delegate: self
        )
        
        WindowsManager.sharedInstance.showContactWindow(
            vc: vc,
            window: view.window,
            title: "Manage Payments",
            identifier: "invoice-management-window",
            size: CGSize(width: 414, height: 600)
        )
    }
    
    func handleSentClick() {
        WindowsManager.sharedInstance.closeIfExists(
            identifier: "invoice-management-window"
        )
        
        let vc = SendPaymentForInvoiceVC.instantiate()
        
        WindowsManager.sharedInstance.showContactWindow(
            vc: vc,
            window: view.window,
            title: "Manage Payments",
            identifier: "invoice-management-window",
            size: CGSize(width: 414, height: 325)
        )
    }
    
    
    func handleInvoiceCreation(invoice:String,amount:Int){
        WindowsManager.sharedInstance.closeIfExists(
            identifier: "invoice-management-window"
        )
        
        let vc = DisplayInvoiceVC.instantiate(
            qrCodeString: invoice,
            amount: amount
        )
        
        WindowsManager.sharedInstance.showContactWindow(
            vc: vc,
            window: view.window,
            title: "Manage Payments",
            identifier: "invoice-management-window",
            size: CGSize(width: 414, height: 700)
        )
    }
    
    func didCreateMessage(message: TransactionMessage) {}
    func didFailInvoiceOrPayment() {}
    func shouldCreateCall(mode: VideoCallHelper.CallMode) {}
    func shouldSendPaymentFor(paymentObject: PaymentViewModel.PaymentObject, callback: ((Bool) -> ())?) {}
    func shouldReloadMuteState() {}
    func shouldDimiss() {}
    func shouldGoForward(paymentViewModel: PaymentViewModel) {}
    func shouldGoBack(paymentViewModel: PaymentViewModel) {}
    func shouldSendPaymentFor(paymentObject: PaymentViewModel.PaymentObject) {}
}

extension ChatListViewController : NewChatListViewControllerDelegate {
    func didClickRowAt(
        selectedObjectId: String?,
        chatId: Int?,
        contactId: Int?
    ) {
        updateBalance()
        
        contactChatsContainerViewController.updateWith(
            selectedObjectId: selectedObjectId
        )
        
        tribeChatsContainerViewController.updateWith(
            selectedObjectId: selectedObjectId
        )
        
        delegate?.didClickOnChatRow(
            chatId: chatId,
            contactId: contactId
        )
    }
}

extension ChatListViewController : NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        searchField?.resignFirstResponder()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        let currentString = (searchField?.stringValue ?? "")
        searchClearButton.isHidden = currentString.isEmpty
        contactsService.updateChatListWith(term: currentString)
    }
}

extension ChatListViewController : HealthCheckDelegate {
    func shouldShowBubbleWith(_ message: String) {
        NewMessageBubbleHelper().showGenericMessageView(text:message, in: view, position: .Top, delay: 3)
    }
}

extension ChatListViewController : NewContactChatDelegate {
    func shouldReloadContacts() {
        updateContactsAndReload()
    }
}

extension ChatListViewController: ChatsSegmentedControlDelegate {
    
    func segmentedControlDidSwitch(
        _ segmentedControl: ChatsSegmentedControl,
        to index: Int
    ) {
        activeTab = DashboardTab(rawValue: index)!
    }
}

extension ChatListViewController {
    enum DashboardTab: Int, Hashable {
        case friends
        case tribes
    }
}

