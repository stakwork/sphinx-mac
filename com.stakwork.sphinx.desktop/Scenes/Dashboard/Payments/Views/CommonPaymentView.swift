//
//  CommonPaymentView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol CommonPaymentViewDelegate: AnyObject {
    func didUpdate(message: String)
    func didUpdate(amount: Int)
    func didUpdateContacts(contact: [UserContact])
    func shouldClose()
    func shouldGoBack()
    func didConfirm()
}

class CommonPaymentView: NSView, LoadableNib {
    
    weak var delegate: CommonPaymentViewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var closeButton: NSButton!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var amountField: CCTextField!
    @IBOutlet weak var amountFieldWidth: NSLayoutConstraint!
    @IBOutlet var messageTextView: PlaceHolderTextView!
    @IBOutlet weak var messageTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var confirmButtonContainer: NSBox!
    @IBOutlet weak var confirmButtonLabel: NSTextField!
    @IBOutlet weak var confirmButton: NSButton!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    var paymentViewModel: PaymentViewModel!
    
    let kMinimumAmountFieldWidth: CGFloat = 70
    let kAmountFieldPadding: CGFloat = 20
    
    let kCharacterLimit = 200
    let kMaximumAmount = 9999999
    
    public enum PaymentViewMode: Int {
        case View
        case Window
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [confirmButton])
        }
    }
    
    var buttonEnabled = false {
        didSet {
            confirmButton.isEnabled = buttonEnabled
            confirmButtonContainer.alphaValue = buttonEnabled ? 1.0 : 0.7
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        amountField.setColor(color: NSColor.Sphinx.Text)
    }
    
    func configureView(
        paymentViewModel: PaymentViewModel,
        delegate: CommonPaymentViewDelegate,
        mode: PaymentViewMode = .View
    ) {
        self.paymentViewModel = paymentViewModel
        self.delegate = delegate
        
        closeButton.title = (getChat()?.isGroup() ?? false) ? "" : ""
        closeButton.isHidden = mode == .Window
        titleLabel.isHidden = mode == .Window
        
        amountField.delegate = self
        amountField.formatter = IntegerValueFormatter()
        
        messageTextView.font = NSFont(name: "Roboto-Regular", size: 16.0)!
        messageTextView.textColor = NSColor.Sphinx.Text
        messageTextView.delegate = self
        messageTextView.alignment = .center
        
        confirmButtonContainer.wantsLayer = true
        confirmButtonContainer.layer?.cornerRadius = confirmButtonContainer.frame.height / 2
    }
    
    func getChat() -> Chat? {
        return paymentViewModel.currentPayment.chat
    }
    
    func set(message: String, amount: Int) {
        messageTextView.string = message
        amountField.stringValue = (amount > 0) ? "\(amount)" : ""
        buttonEnabled = (amount > 0)
        updateBottomBarHeight()
        updateAmountFieldWidth()
    }
    
    func setTitle(title: String, placeHolder: String, buttonLabel: String) {
        messageTextView.setPlaceHolder(color: NSColor.Sphinx.PlaceholderText, font: NSFont(name: "Roboto-Regular", size: 16.0)!, string: placeHolder, alignment: .center)
        titleLabel.stringValue = title
        confirmButtonLabel.stringValue = buttonLabel
    }
    
    @IBAction func confirmButtonClicked(_ sender: Any) {
        loading = true
        
        delegate?.didConfirm()
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        if getChat()?.isPrivateGroup() ?? false {
            delegate?.shouldGoBack()
        } else {
            delegate?.shouldClose()
        }
    }
}

extension CommonPaymentView : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let currentString = amountField.stringValue
        let amount = Int(currentString) ?? 0
        let totalAmount = amount * paymentViewModel.currentPayment.contacts.count
        
        let sending = paymentViewModel.currentPayment.mode == .Payment
        let walletBalance = WalletBalanceService().balance
        
        if totalAmount > walletBalance && sending {
            NewMessageBubbleHelper().showGenericMessageView(text: "balance.too.low".localized, in: self)
            amountField.stringValue = String(currentString.dropLast())
            return
        }
        
        if amount > kMaximumAmount {
            amountField.stringValue = String(currentString.dropLast())
            return
        }
        
        buttonEnabled = (amount > 0)
        updateAmountFieldWidth()
        delegate?.didUpdate(amount: Int(currentString) ?? 0)
    }
    
    func updateAmountFieldWidth() {
        let currentString = amountField.stringValue
        let width = NSTextField().getStringSize(text: currentString, font: amountField.font!).width
        amountFieldWidth.constant = (width < (kMinimumAmountFieldWidth - kAmountFieldPadding)) ? kMinimumAmountFieldWidth : width + kAmountFieldPadding
        amountField.superview?.layoutSubtreeIfNeeded()
    }
}

extension CommonPaymentView : NSTextViewDelegate {
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        if let replacementString = replacementString, replacementString == "\n" {
            return false
        }
        
        let currentString = textView.string as NSString
        let currentChangedString = currentString.replacingCharacters(in: affectedCharRange, with: replacementString ?? "")
        return (currentChangedString.count <= kCharacterLimit)
    }
    
    func textDidChange(_ notification: Notification) {
        updateBottomBarHeight()
        delegate?.didUpdate(message: messageTextView.string)
    }
    
    func updateBottomBarHeight() {
        let messageFieldContentHeight = messageTextView.contentSize.height
        let minimumFieldHeight:CGFloat = 19
        let newFieldHeight = max(messageFieldContentHeight, minimumFieldHeight)
        
        messageTextViewHeight.constant = newFieldHeight
        messageTextView.layoutSubtreeIfNeeded()
    }
}
