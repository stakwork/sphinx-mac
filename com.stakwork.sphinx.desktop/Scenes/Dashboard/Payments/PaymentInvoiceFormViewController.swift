//
//  CreateInvoiceViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import SwiftyJSON

class PaymentInvoiceFormViewController: NSViewController {
    
    weak var childVCDelegate: ChildVCDelegate?
    weak var delegate: ActionsDelegate?
    
    var paymentViewModel : PaymentViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func didCreateMessage() {
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
    
    func handleInvoiceCreation(invoice:String,amount:Int){
        if let delegate = delegate as? ChatListViewController{
            delegate.handleInvoiceCreation(invoice: invoice,amount: amount)
        }
    }
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

