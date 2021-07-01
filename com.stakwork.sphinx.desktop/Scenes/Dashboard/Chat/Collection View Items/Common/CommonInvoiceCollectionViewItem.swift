//
//  CommonInvoiceCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonInvoiceCollectionViewItem : CommonChatCollectionViewItem {
    
    static let kBubbleWidth: CGFloat = 250
    static let kLabelWidth: CGFloat = 210
    static let kLabelTopMargin: CGFloat = 57
    static let kLabelBottomMargin: CGFloat = 77
    static let kLabelBottomMarginWithoutButton: CGFloat = 20
    
    @IBOutlet weak var expirationLabel: NSTextField!
    @IBOutlet weak var invoiceContainerView: NSView!
    @IBOutlet weak var qrCodeIcon: NSImageView!
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var unitLabel: NSTextField!
    @IBOutlet weak var memoLabel: NSTextField!
    @IBOutlet weak var lockSign: NSTextField!
    
    var timer : Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configureExpiry() {
        stopTimer()
        configureTimer()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func configureTimer() {
        updateTimer()
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(CommonInvoiceCollectionViewItem.updateTimer), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
    }
    
    func secondsToMinutes(seconds : Int) -> String {
        let minutes: Int = (seconds % 3600) / 60
        return minutes.timeString
    }
    
    @objc func updateTimer() {
        if let expiryDate = messageRow?.transactionMessage.expirationDate, Date().timeIntervalSince1970 < expiryDate.timeIntervalSince1970 {
            let diff = expiryDate.timeIntervalSince1970 - Date().timeIntervalSince1970
            let minutes = secondsToMinutes(seconds: Int(diff))
            let expirationString = String(format: "expires.in".localized, minutes)
            expirationLabel.stringValue = expirationString
        } else {
            expirationLabel.stringValue = "expired".localized
        }
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()

        lockSign.stringValue = messageRow.transactionMessage.encrypted ? "lock" : ""

        let bubbleSize = getBubbleSize(messageRow: messageRow)
        
        invoiceContainerView.wantsLayer = true
        invoiceContainerView.addDashedBorder(color: getBorderColor(), size: bubbleSize)
        invoiceContainerView.layer?.cornerRadius = 10
        invoiceContainerView.layer?.backgroundColor = NSColor.Sphinx.Body.cgColor

        let amountNumber = messageRow.transactionMessage.amount ?? NSDecimalNumber(value: 0)
        let amountString = Int(truncating: amountNumber).formattedWithSeparator
        amountLabel.stringValue = "\(amountString)"

        memoLabel.font = Constants.kMessageFont
        memoLabel.stringValue = messageRow.getMessageContent()
        addLinksOnLabel(label: memoLabel)

        configureExpiry()

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func getBorderColor() -> NSColor {
        return NSColor.Sphinx.ReceivedBubbleBorder
    }
    
    func getBubbleSize(messageRow: TransactionMessageRow) -> CGSize {
        return CGSize(width: CommonInvoiceCollectionViewItem.kBubbleWidth, height: 0)
    }
    
    public static func getLabelHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let textColorAndFont = messageRow.getMessageAttributes()
        let (_, size) = MessageBubbleView.getLabel(maxWidth: kLabelWidth, textColorAndFont: textColorAndFont)
        return textColorAndFont.0.isEmpty ? -17 : size.height
    }
}
