//
//  CustomCreateInvoiceViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CreateInvoiceViewController : PaymentInvoiceFormViewController {
    
    @IBOutlet weak var paymentView: CommonPaymentView!
    
    var mode = CommonPaymentView.PaymentViewMode.View
    
    static func instantiate(
        childVCDelegate: ChildVCDelegate,
        viewModel: PaymentViewModel,
        delegate: ActionsDelegate?,
        mode: CommonPaymentView.PaymentViewMode = .View
    ) -> CreateInvoiceViewController {
        
        let viewController = StoryboardScene.Dashboard.createInvoiceViewController.instantiate()
        viewController.childVCDelegate = childVCDelegate
        viewController.paymentViewModel = viewModel
        viewController.delegate = delegate
        viewController.mode = mode
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
    }
    
    func configureView() {
        paymentView.configureView(paymentViewModel: paymentViewModel, delegate: self, mode: mode)
        paymentView.setTitle(title: "request.amount.upper".localized, placeHolder: "memo".localized, buttonLabel: "confirm.upper".localized)
    }
    
    override func performConfirmAction() {
        super.performConfirmAction()

        createPaymentRequest()
    }
    
    func createPaymentRequest() {
        paymentViewModel.shouldCreateInvoice(callback: { invoice in
            if let invoice = invoice {
                let amount = self.paymentViewModel.currentPayment.amount ?? -1
                self.handleInvoiceCreation(invoice: invoice, amount: amount)
            } else {
                self.didCreateMessage()
            }
        }, errorCallback: { errorMessage in
            self.paymentView.loading = false
            self.didFailWith(message: errorMessage)
        })
    }
    
    override func saveMessage(message: String) {
        paymentViewModel.currentPayment.memo = message
    }
}
