//
//  AuthorizeAppView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 19/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol AuthorizeAppViewDelegate: AnyObject {
    func shouldAuthorizeWith(amount: Int, dict: [String: AnyObject])
    func shouldCloseAuthorizeView()
}

class AuthorizeAppView: NSView, LoadableNib {
    
    weak var delegate: AuthorizeAppViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var appNameLabel: NSTextField!
    @IBOutlet weak var amountTextField: NSTextField!
    @IBOutlet weak var confirmButtonContainer: NSBox!
    @IBOutlet weak var confirmButtonLabel: NSTextField!
    @IBOutlet weak var confirmButton: NSButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var fieldContainer: NSBox!
    @IBOutlet weak var fieldTopLabel: NSTextField!
    @IBOutlet weak var fieldBottomLabel: NSTextField!
    
    var dict : [String: AnyObject] = [:]
    
    let kHeightWithBudgetField: CGFloat = 500
    let kHeightWithoutBudgetField: CGFloat = 350
    
    var confirmButtonEnabled = false {
        didSet {
            confirmButton.isEnabled = confirmButtonEnabled
            confirmButtonContainer.alphaValue = confirmButtonEnabled ? 1.0 : 0.7
        }
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [confirmButton])
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        confirmButtonContainer.wantsLayer = true
        confirmButtonContainer.layer?.cornerRadius = confirmButtonContainer.frame.height / 2
        
        amountTextField.delegate = self
        amountTextField.formatter = IntegerValueFormatter()
    }
    
    func configureFor(url: String, delegate: AuthorizeAppViewDelegate, dict: [String: AnyObject]) -> CGFloat {
        self.delegate = delegate
        self.dict = dict
        
        confirmButtonEnabled = false
        loading = false
        
        if let url = URL(string: url), let host = url.host {
            appNameLabel.stringValue = host
        } else {
            appNameLabel.stringValue = url
        }
        
        if let noBudget = dict["noBudget"] as? Bool, noBudget {
            configureWithNoBudget()
            return kHeightWithoutBudgetField
        }
        
        return kHeightWithBudgetField
    }
    
    func configureWithNoBudget() {
        confirmButtonEnabled = true
        fieldContainer.isHidden = true
        fieldTopLabel.isHidden = true
        fieldBottomLabel.isHidden = true
    }
    
    @IBAction func closeButtonClicked(_ sender: NSButton) {
        delegate?.shouldCloseAuthorizeView()
    }
    
    @IBAction func confirmButtonClicked(_ sender: NSButton) {
        loading = true
        
        let amount = getCurrentAmount()
        delegate?.shouldAuthorizeWith(amount: amount, dict: dict)
    }
}

extension AuthorizeAppView : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let amount = getCurrentAmount()
        let walletBalance = WalletBalanceService().balance
        
        if amount > walletBalance {
            NewMessageBubbleHelper().showGenericMessageView(text: "balance.too.low".localized, in: self)
            amountTextField.stringValue = String(amountTextField.stringValue.dropLast())
            return
        }
        
        if amount > 100000 {
            amountTextField.stringValue = String(amountTextField.stringValue.dropLast())
            return
        }
        
        confirmButtonEnabled = (amount > 0)
    }
    
    func getCurrentAmount() -> Int {
        let currentString = amountTextField.stringValue
        let amount = Int(currentString) ?? 0
        return amount
    }
}
