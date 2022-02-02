//
//  CommonPaymentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonPaymentCollectionViewItem : CommonChatCollectionViewItem {
    
    static let kPaymentRowHeight: CGFloat = 65.0
    
    @IBOutlet weak var paymentLabel: NSTextField!
    @IBOutlet weak var dot: NSBox!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dot.wantsLayer = true
        dot.layer?.cornerRadius = dot.frame.size.height / 2
    }
    
    func configurePayment() {
        guard let messageRow = messageRow else {
            return
        }
        
        let dateString = messageRow.transactionMessage.messageDate.getStringDate(format: "EEEE, MMM dd")
        let paidString = String(format: "invoice.paid.on".localized, "\(dateString)\(messageRow.transactionMessage.messageDate.daySuffix())")
        paymentLabel.stringValue = paidString
    }
    
    public static func getRowHeight() -> CGFloat {
        return CommonPaymentCollectionViewItem.kPaymentRowHeight
    }
    
}
