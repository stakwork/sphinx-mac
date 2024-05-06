//
//  ChildVCContainer.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol ChildVCDelegate: AnyObject {
    func shouldDimiss()
    func shouldGoForward(paymentViewModel: PaymentViewModel)
    func shouldGoBack(paymentViewModel: PaymentViewModel)
    func shouldSendPaymentFor(paymentObject: PaymentViewModel.PaymentObject)
}

protocol ActionsDelegate: AnyObject {
    func didCreateMessage()
    func didFailInvoiceOrPayment()
    func shouldCreateCall(mode: VideoCallHelper.CallMode)
    func shouldSendPaymentFor(paymentObject: PaymentViewModel.PaymentObject, callback: ((Bool) -> ())?)
    func shouldReloadMuteState()
    func didDismissView()
}

class ChildVCContainer: NSView, LoadableNib {
    
    weak var delegate: ActionsDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var contentBox: NSBox!
    @IBOutlet weak var optionsMenuContainer: NSView!
    @IBOutlet weak var callOptionsContainer: NSView!
    @IBOutlet weak var tribeMemberPopupView: TribeMemberPopupView!
    @IBOutlet weak var childVCContainer: NSView!
    @IBOutlet weak var requestOptionContainer: NSView!
    @IBOutlet weak var notificationLevelView: NotificationLevelView!
    
    @IBOutlet weak var containerHeight: NSLayoutConstraint!
    @IBOutlet weak var containerWidth: NSLayoutConstraint!
    
    let menuSize = CGSize(width: 300, height: 170)
    let oneOptionMenuSize = CGSize(width: 300, height: 115)
    let invoicePaymentSize = CGSize(width: 380, height: 500)
    let groupMembersSize = CGSize(width: 380, height: 620)
    let paymentTemplatesSize = CGSize(width: 560, height: 620)
    let tribeMemberPopupSize = CGSize(width: 280, height: 350)
    let notificationLevelPopupSize = CGSize(width: 300, height: 230)
    
    var parentVC : NSViewController? = nil
    var childVC : NSViewController? = nil
    
    var chat : Chat? = nil
    var message: TransactionMessage? = nil
    
    public enum ChildVCOptionsMenuButton: Int {
        case Request
        case Send
        case Audio
        case Video
        case Cancel
    }
    
    enum ViewMode: Int {
        case RequestAmount
        case SendAmount
        case PaymentTemplates
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        resetAllViews()
    }

    override func mouseDown(with event: NSEvent) {}

    func resetAllViews() {
        removeChildVC()
        
        optionsMenuContainer.isHidden = true
        callOptionsContainer.isHidden = true
        childVCContainer.isHidden = true
        tribeMemberPopupView.isHidden = true
        notificationLevelView.isHidden = true
        
        alphaValue = 0.0
        isHidden = true
    }
    
    func prepareMenuViewSize() {
        let menuSize = getMenuSize()
        containerWidth.constant = menuSize.width
        containerHeight.constant = menuSize.height
        requestOptionContainer.isHidden = (chat?.isPrivateGroup() ?? false)
        
        layoutSubtreeIfNeeded()
    }
    
    func prepareTribeMemberPopupSize() {
        containerWidth.constant = tribeMemberPopupSize.width
        containerHeight.constant = tribeMemberPopupSize.height
        
        layoutSubtreeIfNeeded()
    }
    
    func prepareNotificationLevelPopupSize() {
        containerWidth.constant = notificationLevelPopupSize.width
        containerHeight.constant = notificationLevelPopupSize.height
        
        layoutSubtreeIfNeeded()
    }
    
    func preparePopupOn(
        parentVC: NSViewController,
        with chat: Chat?,
        and message: TransactionMessage?,
        delegate: ActionsDelegate
    ) {
        self.parentVC = parentVC
        self.chat = chat
        self.message = message
        self.delegate = delegate
        
        resetAllViews()
    }

    func showPmtOptionsMenuOn(
        parentVC: NSViewController,
        with chat: Chat?,
        delegate: ActionsDelegate
    ) {
        prepareMenuViewSize()
        preparePopupOn(parentVC: parentVC, with: chat, and: nil, delegate: delegate)
        optionsMenuContainer.isHidden = false
        showView()
    }
    
    func showPaymentModeWith(
        parentVC: NSViewController,
        with chat: Chat?,
        delegate: ActionsDelegate,
        mode: ChildVCContainer.ChildVCOptionsMenuButton
    ) {
        switch (mode) {
        case ChildVCOptionsMenuButton.Request:
            showChildVC(
                mode: ViewMode.RequestAmount
            )
        case ChildVCOptionsMenuButton.Send:
            showChildVC(
                mode: ViewMode.SendAmount
            )
        default:
            break
        }
        
        showView()
    }
    
    func showCallOptionsMenuOn(parentVC: NSViewController, with chat: Chat?, delegate: ActionsDelegate) {
        prepareMenuViewSize()
        preparePopupOn(parentVC: parentVC, with: chat, and: nil, delegate: delegate)
        callOptionsContainer.isHidden = false
        showView()
    }
    
    func showTribeMemberPopupViewOn(parentVC: NSViewController, with message: TransactionMessage, delegate: ActionsDelegate) {
        prepareTribeMemberPopupSize()
        preparePopupOn(parentVC: parentVC, with: chat, and: message, delegate: delegate)
        
        tribeMemberPopupView.configureFor(message: message, with: self)
        tribeMemberPopupView.isHidden = false
        
        showView()
    }
    
    func showNotificaionLevelViewOn(parentVC: NSViewController, with chat: Chat, delegate: ActionsDelegate) {
        prepareNotificationLevelPopupSize()
        preparePopupOn(parentVC: parentVC, with: chat, and: message, delegate: delegate)
        
        notificationLevelView.configureWith(chat: chat) {
            self.shouldDimiss()
            self.delegate?.shouldReloadMuteState()
        }
        notificationLevelView.isHidden = false
        
        showView()
    }
    
    func showView() {
        isHidden = false

        AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
            self.alphaValue = 1.0
        })
    }
    
    func hideView() {
        AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
            self.alphaValue = 0.0
        }, completion: {
            self.isHidden = true
            self.delegate?.didDismissView()
        })
    }
    
    func animateSizeTo(size: CGSize, completion: @escaping () -> ()) {
        optionsMenuContainer.isHidden = true
        tribeMemberPopupView.isHidden = true
        childVCContainer.isHidden = true
        
        AnimationHelper.animateViewWith(duration: 0.3, animationsBlock: {
            self.containerWidth.constant = size.width
            self.containerHeight.constant = size.height
            self.layoutSubtreeIfNeeded()
        }, completion: {
            completion()
        })
    }
    
    func getMenuSize() -> CGSize {
        let isGroup = chat?.isPrivateGroup() ?? false
        return CGSize(width: isGroup ? oneOptionMenuSize.width : menuSize.width, height: isGroup ? oneOptionMenuSize.height : menuSize.height)
    }
    
    func getSizeFor(mode: ViewMode) -> CGSize {
        switch(mode) {
        case ViewMode.RequestAmount, ViewMode.SendAmount:
            return invoicePaymentSize
        case ViewMode.PaymentTemplates:
            return paymentTemplatesSize
        }
    }
    
    func getVCFor(mode: ViewMode, paymentVM: PaymentViewModel) -> NSViewController {
        switch(mode) {
        case ViewMode.RequestAmount:
            return CreateInvoiceViewController.instantiate(
                childVCDelegate: self,
                viewModel: paymentVM,
                delegate: delegate
            )
        case ViewMode.SendAmount:
            return SendPaymentViewController.instantiate(
                childVCDelegate: self,
                viewModel: paymentVM,
                delegate: delegate
            )
        case ViewMode.PaymentTemplates:
            return PaymentTemplatesViewController.instantiate(
                childVCDelegate: self,
                viewModel: paymentVM,
                delegate: delegate
            )
        }
        
    }
    
    func showChildVC(mode: ViewMode) {
        removeChildVC()
        
        animateSizeTo(size: getSizeFor(mode: mode), completion: {
            self.addViewController(for: mode)
        })
    }

    func addViewController(for mode: ViewMode) {
        let contact: UserContact? = self.chat?.getContact()
        let paymentMode: PaymentViewModel.PaymentMode = (mode == .SendAmount) ? .Payment : .Request
        let paymentViewModel = PaymentViewModel(chat: chat, contact: contact, message: message, mode: paymentMode)
        let vc = getVCFor(mode: mode, paymentVM: paymentViewModel)
        addChildVC(vc: vc)
    }
    
    func addChildVC(vc: NSViewController) {
        childVC = vc
        parentVC?.addChild(vc)
        vc.view.frame = childVCContainer.frame
        childVCContainer.addSubview(vc.view)
        
        childVCContainer.isHidden = false
    }

    func removeChildVC() {
        if let childVC = childVC {
            childVC.view.removeFromSuperview()
            childVC.removeFromParent()
            self.childVC = nil
        }
        parentVC = nil
    }

    @IBAction func optionButtonClicked(_ sender: Any) {
        if let sender = sender as? NSButton {
            switch(sender.tag) {
            case ChildVCOptionsMenuButton.Request.rawValue:
                showChildVC(mode: ViewMode.RequestAmount)
                break
            case ChildVCOptionsMenuButton.Send.rawValue:
                showChildVC(mode: ViewMode.SendAmount)
                break
            case ChildVCOptionsMenuButton.Audio.rawValue:
                delegate?.shouldCreateCall(mode: .Audio)
                hideView()
                break
            case ChildVCOptionsMenuButton.Video.rawValue:
                delegate?.shouldCreateCall(mode: .All)
                hideView()
                break
            case ChildVCOptionsMenuButton.Cancel.rawValue:
                hideView()
                break
            default:
                break
            }
        }
    }
}

extension ChildVCContainer : ChildVCDelegate {
    
    func shouldDimiss() {
        removeChildVC()
        hideView()
    }
    
    func shouldGoBack(paymentViewModel: PaymentViewModel) {
        if childVC?.isKind(of: PaymentTemplatesViewController.self) ?? false {
            replaceChildVCFor(mode: .SendAmount, paymentViewModel: paymentViewModel)
        }
    }
    
    func shouldGoForward(paymentViewModel: PaymentViewModel) {
        replaceChildVCFor(mode: .PaymentTemplates, paymentViewModel: paymentViewModel)
    }
    
    func replaceChildVCFor(mode: ViewMode, paymentViewModel: PaymentViewModel) {
        let vc = getVCFor(mode: mode, paymentVM: paymentViewModel)
        let size = getSizeFor(mode: mode)
        
        animateSizeTo(size: size, completion: {
            self.replaceChildVC(by: vc)
        })
    }
    
    func replaceChildVC(by vc: NSViewController) {
        self.removeChildVC()
        self.addChildVC(vc: vc)
    }
    
    func shouldSendPaymentFor(paymentObject: PaymentViewModel.PaymentObject) {
        delegate?.shouldSendPaymentFor(paymentObject: paymentObject, callback: { success in
            self.shouldDismissTribeMemberPopup()
        })
    }
}

extension ChildVCContainer : TribeMemberPopupViewDelegate {
    func shouldGoToSendPayment() {
        guard let _ = message else {
            return
        }
        showChildVC(mode: ViewMode.SendAmount)
    }
    
    func shouldDismissTribeMemberPopup() {
        removeChildVC()
        hideView()
    }
}
