//
//  PaymentTemplatesViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PaymentTemplatesViewController: PaymentInvoiceFormViewController {
    
    @IBOutlet weak var paymentTemplatesView: PaymentTemplatesView!
    
    static func instantiate(childVCDelegate: ChildVCDelegate,
                            viewModel: PaymentViewModel,
                            delegate: ActionsDelegate?) -> PaymentTemplatesViewController {
        
        let viewController = StoryboardScene.Dashboard.paymentTemplatesViewController.instantiate()
        viewController.childVCDelegate = childVCDelegate
        viewController.paymentViewModel = viewModel
        viewController.delegate = delegate
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        paymentTemplatesView.configureView(delegate: self, paymentViewModel: paymentViewModel)
        
        let message = paymentViewModel.currentPayment.message ?? ""
        let amount = (paymentViewModel.currentPayment.amount ?? 0)
        paymentTemplatesView.set(message: message, amount: amount)
    }
    
    override func performConfirmAction() {
        super.performConfirmAction()
        
        sendDirectPayment()
    }
    
    private func sendDirectPayment() {
        paymentViewModel.shouldSendDirectPayment(callback: {
            self.didCreateMessage()
        }, errorCallback: { errorMessage in
            self.paymentTemplatesView.loading = false
            self.didFailWith(message: errorMessage)
        })
    }
    
}
