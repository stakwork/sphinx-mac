//
//  DisplayInvoiceVC.swift
//  Sphinx
//
//  Created by James Carucci on 4/7/23.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation
import Cocoa

class DisplayInvoiceVC : NSViewController{
    
    @IBOutlet weak var qrCodeImageView: NSImageView!
    @IBOutlet weak var shareInvoiceStringButton: NSView!
    @IBOutlet weak var shareQRImageButton: NSView!
    @IBOutlet weak var invoiceStringDisplay: NSTextField!
    @IBOutlet weak var amountTextField: NSTextField!
    @IBOutlet weak var codeStringLabel: VerticallyCenteredButtonCell!
    @IBOutlet weak var codeImageLabel: VerticallyCenteredButtonCell!
    
    var qrString : String? = nil
    var amount : Int? = nil
    
    static func instantiate(
        qrCodeString:String,
        amount:Int
    ) -> DisplayInvoiceVC {
        let viewController = StoryboardScene.Payments.displayInvoiceVC.instantiate()
        viewController.qrString = qrCodeString
        viewController.amount = amount
        return viewController
    }
    
    
    override func viewDidLoad() {
        if let qrString = qrString{
            qrCodeImageView.image = NSImage.qrCode(from: qrString, size: qrCodeImageView.frame.size)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self.view.bringSubviewToFront(self.qrCodeImageView)
                self.view.bringSubviewToFront(self.shareInvoiceStringButton)
                self.view.bringSubviewToFront(self.shareQRImageButton)
                self.shareInvoiceStringButton.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(self.copyInvoiceText)))
                self.shareQRImageButton.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(self.copyInvoiceImage)))
                self.invoiceStringDisplay.stringValue = qrString
                var amountText = ""
                if let amount = self.amount
                {
                    amountText = "\(String(amount)) sats"
                    self.view.bringSubviewToFront(self.amountTextField)
                }
                self.amountTextField.stringValue = amountText
                self.view.bringSubviewToFront(self.invoiceStringDisplay)
            })
            
        }
        self.view.setBackgroundColor(color: NSColor.Sphinx.Body)
        self.addLocalization()
    }
    
    func addLocalization(){
        codeStringLabel.title = "copy.invoice.string".localized
        codeImageLabel.title = "copy.invoice.image".localized
    }
    
    @objc func copyInvoiceImage(){
        if let image = self.view.bitmapImage(){
            ClipboardHelper.addImageToClipboard(image: image)
        }
        
    }
    
    @objc func copyInvoiceText(){
        if let qrString = qrString{
            ClipboardHelper.copyToClipboard(text: qrString)
        }
    }
}
