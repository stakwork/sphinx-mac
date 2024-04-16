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
        
        DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
            self.searchField?.isEnabled = true
        })
    }
}

extension ChatListViewController : ChildVCDelegate, ActionsDelegate {
    func handleReceiveClick() {
        let vc = CreateInvoiceViewController.instantiate(
            childVCDelegate: self,
            viewModel: PaymentViewModel(mode: .Request),
            delegate: self,
            mode: .Window
        )
        
        WindowsManager.sharedInstance.showPaymentWindow(
            vc: vc,
            title: "request.amount".localized,
            height: 500
        )
    }
    
    func handleSentClick() {
        let vc = SendPaymentForInvoiceVC.instantiate()
        
        WindowsManager.sharedInstance.showContactWindow(
            vc: vc,
            title: "Payments",
            identifier: "invoice-management-window",
            height: 447
        )
    }
    
    
    func handleInvoiceCreation(invoice:String, amount:Int){
        let vc = DisplayInvoiceVC.instantiate(
            qrCodeString: invoice,
            amount: amount
        )
        
        WindowsManager.sharedInstance.showContactWindow(
            vc: vc,
            title: "payment.request".localized,
            identifier: "invoice-management-window",
            height: 629
        )
    }
    
    func didDismissView() {}
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
    func shouldResetContactView(deletedContactId: Int) {
        delegate?.shouldResetContactView(deletedContactId: deletedContactId)
    }
    
    func didClickRowAt(
        chatId: Int?,
        contactId: Int?
    ) {
        contactChatsContainerViewController.updateSnapshot()
        tribeChatsContainerViewController.updateSnapshot()
        
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
        if (obj.object as? NSTextField) == searchField {
            let currentString = (searchField?.stringValue ?? "")
            searchClearButton.isHidden = currentString.isEmpty
            contactsService.updateChatListWith(term: currentString)
        }
    }
}

extension ChatListViewController : HealthCheckDelegate {
    func shouldShowBubbleWith(_ message: String) {
        NewMessageBubbleHelper().showGenericMessageView(text:message, in: view, position: .Top, delay: 3)
    }
}

extension ChatListViewController : NewContactChatDelegate {
    func shouldReloadContacts() {
        updateBalanceAndCheckVersion()
    }
}

extension ChatListViewController: ChatsSegmentedControlDelegate {
    
    func segmentedControlDidSwitch(
        _ segmentedControl: ChatsSegmentedControl,
        to index: Int
    ) {
        if let tab = DashboardTab(rawValue: index) {
            contactsService.selectedTab = tab
            
            setActiveTab(tab)
        }
    }
}

