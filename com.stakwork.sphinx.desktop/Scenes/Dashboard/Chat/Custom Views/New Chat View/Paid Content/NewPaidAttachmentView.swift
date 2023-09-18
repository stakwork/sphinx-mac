//
//  NewPaidAttachmentView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol PaidAttachmentViewDelegate: AnyObject {
    func didTapPayButton()
}

class NewPaidAttachmentView: NSView, LoadableNib {
    
    weak var delegate: PaidAttachmentViewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var purchaseAmountLabel: NSTextField!
    @IBOutlet weak var payAttachmentContainer: NSBox!
    @IBOutlet weak var processingPaymentContainer: NSBox!
    @IBOutlet weak var purchaseDeniedContainer: NSBox!
    @IBOutlet weak var purchaseAcceptContainer: NSBox!
    @IBOutlet weak var processingLoadingWheel: NSProgressIndicator!
    @IBOutlet weak var payButton: CustomButton!
    
    static let kViewHeight: CGFloat = 50

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setup()
    }
    
    func setup() {
        payButton.cursor = .pointingHand
        
        processingLoadingWheel.set(tintColor: NSColor.white)
        
        payAttachmentContainer.cornerRadius = 8
        processingPaymentContainer.cornerRadius = 8
        purchaseDeniedContainer.cornerRadius = 8
        purchaseAcceptContainer.cornerRadius = 8
    }
    
    func configure(
        paidContent: BubbleMessageLayoutState.PaidContent,
        and delegate: PaidAttachmentViewDelegate?
    ) {
        self.delegate = delegate
        
        let priceString = paidContent.price.formattedWithSeparator
        purchaseAmountLabel.stringValue = "\(priceString) SAT"

        payAttachmentContainer.isHidden = true
        processingPaymentContainer.isHidden = true
        purchaseAcceptContainer.isHidden = true
        purchaseDeniedContainer.isHidden = true
        
        processingLoadingWheel.isHidden = true
        processingLoadingWheel.stopAnimation(nil)

        switch(paidContent.status) {
        case TransactionMessage.TransactionMessageType.purchase:
            processingPaymentContainer.isHidden = false
            
            processingLoadingWheel.isHidden = false
            processingLoadingWheel.startAnimation(nil)
            break
        case TransactionMessage.TransactionMessageType.purchaseAccept:
            purchaseAcceptContainer.isHidden = false
            break
        case TransactionMessage.TransactionMessageType.purchaseDeny:
            purchaseDeniedContainer.isHidden = false
            break
        default:
            payAttachmentContainer.isHidden = false
            break
        }
    }
    
    @IBAction func payButtonClicked(_ sender: Any) {
        delegate?.didTapPayButton()
    }
}
