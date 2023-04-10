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
    
    static func instantiate(childVCDelegate: ChildVCDelegate,
                            viewModel: PaymentViewModel,
                            delegate: ActionsDelegate?) -> CreateInvoiceViewController {
        
        let viewController = StoryboardScene.Dashboard.createInvoiceViewController.instantiate()
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
        paymentView.setTitle(title: "request.amount.upper".localized, placeHolder: "memo".localized, buttonLabel: "confirm.upper".localized)
    }
    
    override func performConfirmAction() {
        super.performConfirmAction()

        createPaymentRequest()
    }
    
    func createPaymentRequest() {
        paymentViewModel.shouldCreateInvoice(callback: { message,invoice in
            if let message = message{
                self.didCreateMessage(message: message)
            }
            else if let invoice = invoice{
                print(invoice)
                self.handleInvoiceCreation(invoice: invoice)
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
