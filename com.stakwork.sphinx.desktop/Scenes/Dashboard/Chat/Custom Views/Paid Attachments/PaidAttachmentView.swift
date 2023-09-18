//
//  PaidAttachmentView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

//protocol PaidAttachmentViewDelegate: AnyObject {
//    func didTapPayButton()
//}

class PaidAttachmentView: NSView, LoadableNib {
    
    weak var delegate: PaidAttachmentViewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var paidAttachmentBubble: PaidAttachmentBubbleView!
    @IBOutlet weak var payAttachmentContainer: NSBox!
    @IBOutlet weak var processingPaymentContainer: NSBox!
    @IBOutlet weak var purchaseSucceedContainer: NSBox!
    @IBOutlet weak var purchaseDeniedContainer: NSBox!
    @IBOutlet weak var purchaseAmountLabel: NSTextField!
    @IBOutlet weak var purchaseLoadingWheel: NSProgressIndicator!
    @IBOutlet weak var payButton: CustomButton!
    
    static let kViewHeight:CGFloat = 50
    
    override var isFlipped:Bool {
        get {
            return true
        }
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: purchaseLoadingWheel, color: NSColor.white, controls: [])
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
   
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        payButton.cursor = .pointingHand
    }
    
    func configure(messageRow: TransactionMessageRow, delegate: PaidAttachmentViewDelegate) {
        guard let message = messageRow.transactionMessage else {
            return
        }
        let shouldShow = messageRow.shouldShowPaidAttachmentView()
        isHidden = !shouldShow
        
        if !shouldShow {
            return
        }
        
        self.delegate = delegate
        
        let price = message.getAttachmentPrice() ?? 0
        let status = message.getPurchaseStatus(queryDB: false)
        configure(status: status, price: price)
        
        paidAttachmentBubble.showPaidAttachmentBubble(nextMessage: message.consecutiveMessages.nextMessage, color: getBackgroundColor(status: status))
    }
    
    func configure(status: TransactionMessage.TransactionMessageType, price: Int) {
        let priceString = price.formattedWithSeparator
        purchaseAmountLabel.stringValue = "\(priceString) SAT"
        
        payAttachmentContainer.isHidden = true
        processingPaymentContainer.isHidden = true
        purchaseSucceedContainer.isHidden = true
        purchaseDeniedContainer.isHidden = true
        loading = false
        
        switch(status) {
        case TransactionMessage.TransactionMessageType.purchase:
            processingPaymentContainer.isHidden = false
            loading = true
            break
        case TransactionMessage.TransactionMessageType.purchaseAccept:
            purchaseSucceedContainer.isHidden = false
            break
        case TransactionMessage.TransactionMessageType.purchaseDeny:
            purchaseDeniedContainer.isHidden = false
            break
        default:
            payAttachmentContainer.isHidden = false
            break
        }
    }
    
    func getBackgroundColor(status: TransactionMessage.TransactionMessageType) -> NSColor {
        switch(status) {
        case TransactionMessage.TransactionMessageType.purchaseDeny:
            return NSColor.Sphinx.PrimaryRed
        default:
            return NSColor.Sphinx.PrimaryGreen
        }
    }
    
    @IBAction func payButtonClicked(_ sender: Any) {
        AlertHelper.showTwoOptionsAlert(title: "confirm.purchase".localized, message: "confirm.purchase.message".localized, confirm: {
            self.delegate?.didTapPayButton()
        })
    }
    
}
