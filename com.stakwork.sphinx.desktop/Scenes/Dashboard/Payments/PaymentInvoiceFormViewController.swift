//
//  CreateInvoiceViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import SwiftyJSON

protocol ActionsDelegate: AnyObject {
    func didCreateMessage(message: TransactionMessage)
    func didFailInvoiceOrPayment()
    func shouldCreateCall(mode: VideoCallHelper.CallMode)
}

class PaymentInvoiceFormViewController: NSViewController {
    
    weak var childVCDelegate: ChildVCDelegate?
    weak var delegate: ActionsDelegate?
    
    var paymentViewModel : PaymentViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func createLocalMessages(message: JSON?) {
        let (messageObject, success) = paymentViewModel.createLocalMessages(message: message)
        
        NotificationCenter.default.post(name: .onBalanceDidChange, object: nil)
        
        if let messageObject = messageObject, success {
            delegate?.didCreateMessage(message: messageObject)
            childVCDelegate?.shouldDimiss()
        } else {
            shouldDismissOnFail()
        }
    }
    
    func didCreateMessage(message: TransactionMessage) {
        delegate?.didCreateMessage(message: message)
        childVCDelegate?.shouldDimiss()
    }
    
    func shouldDismissOnFail() {
        delegate?.didFailInvoiceOrPayment()
        childVCDelegate?.shouldDimiss()
    }
    
    func didFailWith(message: String?) {
        if let errorMessage = message {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: errorMessage)
        } else {
            shouldDismissOnFail()
        }
    }
    
    func performConfirmAction() {}
    
    func saveMessage(message: String) {}
}

extension PaymentInvoiceFormViewController : CommonPaymentViewDelegate {
    func didUpdate(message: String) {
        saveMessage(message: message)
    }
    
    func didUpdate(amount: Int) {
        paymentViewModel.currentPayment.amount = amount
    }
    
    func shouldClose() {
        childVCDelegate?.shouldDimiss()
    }
    
    func shouldGoBack() {
        childVCDelegate?.shouldGoBack(paymentViewModel: paymentViewModel)
    }
    
    func didConfirm() {
        performConfirmAction()
    }
    
    func didUpdateContacts(contact: [UserContact]) {}
}

