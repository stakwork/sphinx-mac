//
//  SendPaymentVC.swift
//  Sphinx
//
//  Created by James Carucci on 4/11/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation

class SendPaymentVC:NSViewController{
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var addressField: NSTextField!
    @IBOutlet weak var confirmButton: NSView!
    @IBOutlet weak var scannerOverlay: NSView!
    @IBOutlet weak var scannerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var paymentContainerView: NSView!
    @IBOutlet weak var paymentContainerAmountField: NSTextField!
    @IBOutlet weak var paymentContainerExpirationField: NSTextField!
    @IBOutlet weak var paymentContainerMemoField: NSTextField!
    @IBOutlet weak var payInvoiceButton: NSView!
    @IBOutlet weak var closeButton: NSButton!
    
    @IBOutlet weak var paymentContainerToCheckInvoiceTopConstraint: NSLayoutConstraint!
    
    
    let prDecoder = PaymentRequestDecoder()
    
    static func instantiate(

    ) -> SendPaymentVC {
        let viewController = StoryboardScene.Payments.sendPaymentVC.instantiate()
        return viewController
    }
    
    override func viewDidLoad() {
        self.paymentContainerView.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.view.bringSubviewToFront(self.titleLabel)
            self.view.bringSubviewToFront(self.confirmButton)
            //self.view.bringSubviewToFront(self.scannerOverlay)
            self.view.bringSubviewToFront(self.paymentContainerView)
            self.paymentContainerView.setBackgroundColor(color: NSColor.Sphinx.Body)
        })
        //scannerOverlay.setBackgroundColor(color: .purple)
        confirmButton.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(confirmButtonTouched)))
        payInvoiceButton.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(payInvoiceButtonTouched)))
        
        //scannerViewHeight.constant = 0
        //scannerOverlay.layoutSubtreeIfNeeded()
    }
    
    @objc func confirmButtonTouched() {
        let code = addressField.stringValue
        let fixedCode = code.fixInvoiceString().trim()
        confirmButton.isHidden = fixedCode == ""
        
        validateQRString(string: fixedCode)
    }
    
    @objc func payInvoiceButtonTouched(){
        print("paying Invoice")
        if let invoice = prDecoder.paymentRequestString{
            payInvoice(invoice: invoice)
        }
    }
    
    func validateQRString(string: String) {
        //resetLabels()
        
        /*
        if validateSubscriptionQR(string: string) {
            return
        } else if validatePublicKey(string: string) {
            return
        }else if validateInvoice(string: string) {
            return
        } else if validateDeepLinks(string: string) {
            return
        }
        */
        if validateInvoice(string: string) {
            return
        }
        
        confirmButton.isHidden = false
        AlertHelper.showAlert(title: "sorry".localized, message: "code.not.recognized".localized)
    }
    
    func validateInvoice(string: String) -> Bool {
        prDecoder.decodePaymentRequest(paymentRequest: string)
        
        if prDecoder.isPaymentRequest() {
            DispatchQueue.main.async {
                self.showConfirmDetailsView()
            }
            return true
        }
        return false
    }
    
    func showConfirmDetailsView(){
        self.paymentContainerView.isHidden = false
        self.animatePaymentContainer()
        self.view.bringSubviewToFront(paymentContainerView)
        if let amount = self.prDecoder.getAmount(){
            paymentContainerAmountField.stringValue = "\(String(describing: amount))"
        }
        if let expirationDate = prDecoder.getExpirationDate() {
            if Date().timeIntervalSince1970 > expirationDate.timeIntervalSince1970 {
                paymentContainerExpirationField.stringValue = "expired".localized
                //payButton.isHidden = true
                payInvoiceButton.alphaValue = 0.5
                for gestureRecognizer in payInvoiceButton.gestureRecognizers{
                    payInvoiceButton.removeGestureRecognizer(gestureRecognizer)
                }
            }
            else{
                let expirationDateString = expirationDate.getStringFromDate(format:"EEE dd MMM HH:mm:ss", timeZone: TimeZone.current)
                paymentContainerExpirationField.stringValue = expirationDateString
            }
        }
        
        if let memo = prDecoder.getMemo() {
            paymentContainerMemoField.stringValue = memo
        }
        
        for textField in paymentContainerView.subviews.compactMap({$0 as? NSTextField}){
            paymentContainerView.bringSubviewToFront(textField)
        }
        paymentContainerView.bringSubviewToFront(payInvoiceButton)
        self.paymentContainerView.bringSubviewToFront(closeButton)
    }
    
    func animatePaymentContainer(show:Bool=true){
        paymentContainerToCheckInvoiceTopConstraint.constant = show ? (0) : (130)
        AnimationHelper.animateViewWith(duration: 0.2, animationsBlock: {
            self.paymentContainerView.layoutSubtreeIfNeeded()
        })
    }
    
    func payInvoice(invoice:String){
        //invoiceLoading = true
        
        var parameters = [String : AnyObject]()
        parameters["payment_request"] = invoice as AnyObject?

        API.sharedInstance.payInvoice(parameters: parameters, callback: { payment in
            AlertHelper.showAlert(title: "generic.success.title".localized, message: "invoice.paid".localized)
            DelayPerformedHelper.performAfterDelay(seconds: 0.25, completion: {
                WindowsManager.sharedInstance.closeIfExists(identifier: "invoice-management-window")
            })
        }, errorCallback: {
            //self.invoiceLoading = false
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            self.animatePaymentContainer(show:false)
        })
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        self.animatePaymentContainer(show:false)
    }
    
}


