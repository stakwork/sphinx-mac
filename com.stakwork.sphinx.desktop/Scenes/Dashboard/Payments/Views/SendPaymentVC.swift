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
    
    
    let prDecoder = PaymentRequestDecoder()
    
    static func instantiate(

    ) -> SendPaymentVC {
        let viewController = StoryboardScene.Payments.sendPaymentVC.instantiate()
        return viewController
    }
    
    override func viewDidLoad() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.view.bringSubviewToFront(self.titleLabel)
            self.view.bringSubviewToFront(self.confirmButton)
            self.view.bringSubviewToFront(self.scannerOverlay)
        })
        scannerOverlay.setBackgroundColor(color: .purple)
        confirmButton.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(confirmButtonTouched)))
    }
    
    @objc func confirmButtonTouched() {
        let code = addressField.stringValue
        let fixedCode = code.fixInvoiceString().trim()
        confirmButton.isHidden = fixedCode == ""
        
        validateQRString(string: fixedCode)
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
                //self.completeAndShowPRDetails()
                print(self.prDecoder.getAmount())
                print(self.prDecoder.getExpirationDate())
            }
            return true
        }
        return false
    }
    
    func showConfirmDetailsView(){
        
    }
}


