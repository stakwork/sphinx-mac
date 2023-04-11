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
    
    override func viewWillTransition(to newSize: NSSize) {
        super.viewWillTransition(to: newSize)
        print(newSize.width)
    }
    
    func configureHeaderAndBottomBar() {
        NSAppearance.current = view.effectiveAppearance
        
        searchBarContainer.addShadow(location: VerticalLocation.bottom, color: NSColor.black, opacity: 0.2, radius: 5.0)
        bottomBar.addShadow(location: VerticalLocation.top, color: NSColor.black, opacity: 0.2, radius: 5.0)

        searchFieldContainer.wantsLayer = true
        searchFieldContainer.layer?.borderColor = NSColor.Sphinx.LightDivider.cgColor
        searchFieldContainer.layer?.borderWidth = 1
        searchFieldContainer.layer?.cornerRadius = searchFieldContainer.frame.height / 2
    }
    
    func listenForNotifications() {
        healthCheckView.listenForEvents()
        balanceLabel.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(handleBalanceClick)))
        
        NotificationCenter.default.addObserver(forName: .onBalanceDidChange, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            self?.updateBalance()
        }
        
        NotificationCenter.default.addObserver(forName: .onTribeImageChanged, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            guard let vc = self else { return }
            vc.chatListObjectsArray = vc.contactsService.getChatListObjects()
            vc.loadDataSource()
        }
    }
    
    func updateBalance() {
        balanceUnitLabel.stringValue = "sat"
        walletBalanceService.updateBalance(labels: [balanceLabel])
    }
    
    func resetSearchField() {
        searchField?.stringValue = ""
        NotificationCenter.default.post(name: NSControl.textDidChangeNotification, object: searchField)
    }
    
    @objc func handleBalanceClick(){
        print("balance tapped")
        
        let vc = CreateInvoiceViewController.instantiate(childVCDelegate: self, viewModel: PaymentViewModel(mode: .Request), delegate: self)
        WindowsManager.sharedInstance.showContactWindow(vc: vc, window: view.window, title: "Manage Payments", identifier: "invoice-management-window", size: CGSize(width: 414, height: 600))
        
    }
}

extension ChatListViewController : ChildVCDelegate,ActionsDelegate{
    
    func handleInvoiceCreation(invoice:String,amount:Int){
        WindowsManager.sharedInstance.closeIfExists(identifier: "invoice-management-window")
        let vc = DisplayInvoiceVC.instantiate(qrCodeString: invoice,amount: amount)
        WindowsManager.sharedInstance.showContactWindow(vc: vc, window: view.window, title: "Manage Payments", identifier: "invoice-management-window", size: CGSize(width: 414, height: 700))
    }
    
    func didCreateMessage(message: TransactionMessage) {
        
    }
    
    func didFailInvoiceOrPayment() {
        
    }
    
    func shouldCreateCall(mode: VideoCallHelper.CallMode) {
        
    }
    
    func shouldSendPaymentFor(paymentObject: PaymentViewModel.PaymentObject, callback: ((Bool) -> ())?) {
        
    }
    
    func shouldReloadMuteState() {
        
    }
    
    func shouldDimiss() {
        
    }
    
    func shouldGoForward(paymentViewModel: PaymentViewModel) {
        
    }
    
    func shouldGoBack(paymentViewModel: PaymentViewModel) {
        
    }
    
    func shouldSendPaymentFor(paymentObject: PaymentViewModel.PaymentObject) {
        
    }
    
    
}

extension ChatListViewController : ChatListDataSourceDelegate {
    func didClickOnChatRow(object: ChatListCommonObject) {
        updateBalance()
        delegate?.didClickOnChatRow(object: object)
    }
}

extension ChatListViewController : NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        searchField?.resignFirstResponder()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        let currentString = (searchField?.stringValue ?? "")
        searchClearButton.isHidden = currentString.isEmpty
        chatListObjectsArray = contactsService.getObjectsWith(searchString: currentString as String)
        loadDataSource()
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

