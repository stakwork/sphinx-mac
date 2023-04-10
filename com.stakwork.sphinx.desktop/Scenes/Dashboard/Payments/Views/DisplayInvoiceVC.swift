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
    @IBOutlet weak var receiveInvoiceTitle: NSTextField!
    @IBOutlet weak var shareInvoiceStringButton: NSView!
    @IBOutlet weak var shareQRImageButton: NSView!
    @IBOutlet weak var invoiceStringDisplay: NSTextField!
    
    var qrString : String? = nil
    
    static func instantiate(
        qrCodeString:String
    ) -> DisplayInvoiceVC {
        let viewController = StoryboardScene.Payments.displayInvoiceVC.instantiate()
        viewController.qrString = qrCodeString
        return viewController
    }
    
    
    override func viewDidLoad() {
        if let qrString = qrString{
            qrCodeImageView.image = NSImage.qrCode(from: qrString, size: qrCodeImageView.frame.size)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self.view.bringSubviewToFront(self.qrCodeImageView)
                self.view.bringSubviewToFront(self.receiveInvoiceTitle)
                self.view.bringSubviewToFront(self.shareInvoiceStringButton)
                self.view.bringSubviewToFront(self.shareQRImageButton)
                self.shareInvoiceStringButton.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(self.copyInvoiceText)))
                self.shareQRImageButton.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(self.copyInvoiceImage)))
                self.invoiceStringDisplay.stringValue = qrString
                self.view.bringSubviewToFront(self.invoiceStringDisplay)
            })
            
        }
        self.view.setBackgroundColor(color: NSColor.Sphinx.Body)
    }
    
    @objc func copyInvoiceImage(){
        ClipboardHelper.addVcImageToClipboard(vc: self)
    }
    
    @objc func copyInvoiceText(){
        if let qrString = qrString{
            ClipboardHelper.copyToClipboard(text: qrString)
        }
    }
}
