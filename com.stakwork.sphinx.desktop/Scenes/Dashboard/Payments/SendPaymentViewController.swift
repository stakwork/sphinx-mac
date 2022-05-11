//
//  SendPaymentViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class SendPaymentViewController : PaymentInvoiceFormViewController {
    
    @IBOutlet weak var paymentView: CommonPaymentView!
    
    static func instantiate(childVCDelegate: ChildVCDelegate,
                            viewModel: PaymentViewModel,
                            delegate: ActionsDelegate?) -> SendPaymentViewController {
        
        let viewController = StoryboardScene.Dashboard.sendPaymentViewController.instantiate()
        viewController.childVCDelegate = childVCDelegate
        viewController.paymentViewModel = viewModel
        viewController.delegate = delegate
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
    }
    
    func configureView() {
        paymentView.configureView(paymentViewModel: paymentViewModel, delegate: self)
        paymentView.setTitle(title: "send.payment.upper".localized, placeHolder: "message".localized, buttonLabel: "continue".localized.uppercased())
        
        let message = paymentViewModel.currentPayment.message ?? ""
        let amount = (paymentViewModel.currentPayment.amount ?? 0)
        paymentView.set(message: message, amount: amount)
    }
    
    override func performConfirmAction() {
        super.performConfirmAction()
        
        if paymentViewModel.isTribePayment() {
            sendTribePayment()
        } else {
            goToPaymentTemplates()
        }
    }
    
    private func sendTribePayment() {
        if let _ = paymentViewModel.currentPayment.transactionMessage {
            childVCDelegate?.shouldSendPaymentFor(paymentObject: paymentViewModel.currentPayment)
        }
    }
    
    private func goToPaymentTemplates() {
        childVCDelegate?.shouldGoForward(paymentViewModel: paymentViewModel)
    }
    
    override func saveMessage(message: String) {
        paymentViewModel.currentPayment.message = message
    }
}
