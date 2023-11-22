//
//  TransactionCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 22/11/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class TransactionCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var backgroundColorBox: NSBox!
    @IBOutlet weak var topView: NSView!
    @IBOutlet weak var bottomView: NSView!
    
    @IBOutlet weak var paymentIcon: NSImageView!
    @IBOutlet weak var addressLabel: NSTextField!
    @IBOutlet weak var failedPaymentLabel: NSTextField!
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var dayOfWeekLabel: NSTextField!
    @IBOutlet weak var dayOfMonthLabel: NSTextField!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var errorMessageLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configureCell(transaction: PaymentTransaction?) {
        guard let transaction = transaction else {
            return
        }
        
        self.backgroundColorBox.fillColor = transaction.isIncoming() ? NSColor.Sphinx.TransactionBG : NSColor.Sphinx.HeaderBG
        
        let directionPmtImage = NSImage(
            named: transaction.isIncoming() ? "transaction-received-icon" : "transaction-sent-icon"
        )
        let failedPmtImage = NSImage(named: "transaction-warning-icon")
        
        paymentIcon.image = transaction.isFailed() ? failedPmtImage : directionPmtImage
        
        failedPaymentLabel.isHidden = !transaction.isFailed()
        
        let bottomViewVisible = transaction.isFailed() && transaction.expanded
        bottomView.isHidden = !bottomViewVisible
        errorMessageLabel.stringValue = "\("transactions.failure-reason".localized) \(transaction.errorMessage ?? "-")"
        
        if let users = transaction.getUsers() {
            addressLabel.stringValue = users
        } else {
            addressLabel.stringValue = "-"
        }
        
        amountLabel.stringValue = (transaction.amount ?? 0).formattedWithSeparator
                
        if let date = transaction.date {
            dayOfWeekLabel.stringValue = date.getStringDate(format: "EEE")
            dayOfMonthLabel.stringValue = date.getStringDate(format: "MMM dd")
            timeLabel.stringValue = date.getStringDate(format: "hh:mm a")
        } else {
            dayOfWeekLabel.stringValue = "-"
            dayOfMonthLabel.stringValue = "-"
            timeLabel.stringValue = "-"
        }
    }
    
}
