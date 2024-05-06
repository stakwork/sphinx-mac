//
//  NewChatViewController+CollectionViewExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage
import SwiftyJSON

extension NewChatViewController {
    func configureCollectionView() {
        chatCollectionView.alphaValue = 0.0
        
        if let ds = chatTableDataSource {
            if ds.isFinalDS() {
                return
            }
        } else if chat == nil {
            chatCollectionView.alphaValue = 1.0
            shimmeringView.toggle(show: false)
        }
        
        if let threadUUID = threadUUID {
            chatTableDataSource = ThreadTableDataSource(
                chat: chat,
                contact: contact,
                owner: owner,
                tribeAdmin: tribeAdmin,
                threadUUID: threadUUID,
                collectionView: chatCollectionView,
                collectionViewScroll: chatScrollView,
                shimmeringView: shimmeringView,
                headerImage: getContactImage(),
                bottomView: chatBottomView,
                webView: botWebView,
                delegate: self
            )
        } else {
            chatTableDataSource = NewChatTableDataSource(
                chat: chat,
                contact: contact,
                owner: owner,
                tribeAdmin: tribeAdmin,
                collectionView: chatCollectionView,
                collectionViewScroll: chatScrollView,
                shimmeringView: shimmeringView,
                headerImage: getContactImage(),
                bottomView: chatBottomView,
                webView: botWebView,
                delegate: self
            )
        }
        
        newChatViewModel?.setDataSource(chatTableDataSource)
    }
    
    func getContactImage() -> NSImage? {
        let imageView = chatTopView.chatHeaderView.profileImageView
        
        if imageView?.isHidden == true {
            return nil
        }
        
        return imageView?.image
    }
}

extension NewChatViewController : NewChatTableDataSourceDelegate {
    func shouldReloadThreadHeader() {
        setupThreadHeaderView()
    }
    
    func configureNewMessagesIndicatorWith(newMsgCount: Int) {
        DispatchQueue.main.async {
            self.newMsgsIndicatorView.configureWith(
                newMessagesCount: newMsgCount,
                hidden: self.chatTableDataSource?.shouldHideNewMsgsIndicator() ?? true,
                andDelegate: self
            )
        }
    }
    
    func didScrollToBottom() {
        self.configureNewMessagesIndicatorWith(
            newMsgCount: 0
        )
        
        if isThread {
            return
        }
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.chat?.setChatMessagesAsSeen()
        })
    }
    
    func didScrollOutOfBottomArea() {
        newMsgsIndicatorView.configureWith(
            newMessagesCount: isThread ? (chatTableDataSource?.getMessagesCount() ?? 0) : nil,
            hidden: chatTableDataSource?.shouldHideNewMsgsIndicator() ?? true
        )
    }
    
    func shouldGoToMediaFullScreenFor(messageId: Int) {
        if let message = TransactionMessage.getMessageWith(id: messageId) {
            delegate?.shouldShowFullMediaFor(message: message)
        }
        
    }
    
    func didTapOnContactWith(pubkey: String, and routeHint: String?) {
        var pubkey = pubkey
        
        if let routeHint = routeHint, routeHint.isNotEmpty {
            pubkey = "\(pubkey):\(routeHint)"
        }
        
        let userInfo: [String: Any] = ["pub-key" : pubkey]
        NotificationCenter.default.post(name: .onPubKeyClick, object: nil, userInfo: userInfo)
    }
    
    func didTapOnTribeWith(joinLink: String) {
        let userInfo: [String: Any] = ["tribe_link" : joinLink]
        NotificationCenter.default.post(name: .onJoinTribeClick, object: nil, userInfo: userInfo)
    }
    
    func didDeleteTribe() {
        delegate?.shouldResetTribeView()
    }
    
    func didUpdateChat(_ chat: Chat) {
        self.chat = chat
    }
    
    func didUpdateChatFromMessage(_ chat: Chat) {
        if self.chat == nil {
            if let contact = self.contact, contact.id == chat.getContact()?.id {
                self.chat = chat
                
                configureFetchResultsController()
                configureCollectionView()
            }
        }
    }
    
    func shouldShowMemberPopupFor(messageId: Int) {
        if let message = TransactionMessage.getMessageWith(id: messageId) {
            childViewControllerContainer.showTribeMemberPopupViewOn(parentVC: self, with: message, delegate: self)
        }
    }
    
    func shouldReplyToMessage(message: TransactionMessage) {
        let isAtBottom = isChatAtBottom()
        
        newChatViewModel.replyingTo = message
        
        ChatTrackingHandler.shared.saveReplyableMessage(
            with: message.id,
            chatId: chat?.id
        )
        
        chatBottomView.configureReplyViewFor(
            message: message,
            owner: self.owner,
            withDelegate: self
        )
        
        if isAtBottom {
            shouldScrollToBottom()
        }
    }
    
    func shouldPayInvoiceFor(messageId: Int) {
        if let message = self.chatTableDataSource?.messagesArray.filter({$0.id == messageId}).first as? TransactionMessage,
           let amount = message.amount as? Int,
           amount > 0 {
            AlertHelper.showTwoOptionsAlert(title: "confirm".localized, message: "confirm.pay.invoice".localized, confirm: {
                self.finalizeInvoicePayment(message: message)
            })
        }
    }
    
    func finalizeInvoicePayment(message: TransactionMessage){
        guard let invoice = message.invoice else {
            return
        }
        
        let prd = PaymentRequestDecoder()
        prd.decodePaymentRequest(paymentRequest: invoice)
        
        guard let chat = message.chat,
              let amount = prd.getAmount(),
              let _ = prd.getExpirationDate(),
              let paymentHash = try? paymentHashFromInvoice(bolt11: invoice) else {
            return
        }
        
        SphinxOnionManager.sharedInstance.payInvoice(invoice: invoice)
        
        let localPaymentMessage : JSON = [
            "id": CrypterManager.sharedInstance.generateCryptographicallySecureRandomInt(upperBound: 100_000) as Any,
            "chat_id": chat.id,
            "sender": 0,
            "type": TransactionMessage.TransactionMessageType.payment.rawValue,
            "amount":amount,
            "amountMsat": amount * 1000,
            "payment_hash": paymentHash,
            "status": TransactionMessage.TransactionMessageStatus.confirmed.rawValue,
            "createdAt": Date(),
            "updatedAt": Date(),
            "payment_request": invoice
        ]
        
        createLocalPayment(payment: localPaymentMessage)
        handleMyInvoicePaymentSettled(paymentHash: paymentHash)
    }
    
    @objc func handleMyInvoicePaymentSettled(paymentHash: String) {
        if let message = TransactionMessage.getPaymentOfInvoiceWith(paymentHash: paymentHash){
            message.setPaymentInvoiceAsPaid()
            SphinxOnionManager.sharedInstance.sendPaymentOfInvoiceMessage(message: message)
        }
    }
    
    func createLocalPayment(payment: JSON?) {
        if let payment = payment {
            if let message = TransactionMessage.insertMessage(
                m: payment,
                existingMessage: TransactionMessage.getMessageWith(id: payment["id"].intValue)
            ).0 {
                self.chatTableDataSource?.reloadAllVisibleRows()
            }
        } else {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            self.chatTableDataSource?.reloadAllVisibleRows()
        }
    }
    
    func isOnStandardMode() -> Bool {
        return viewMode == ViewMode.Standard
    }
    
    func shouldShowOptionsFor(messageId: Int, from button: NSButton) {
        if let message = TransactionMessage.getMessageWith(id: messageId) {
            MessageOptionsHelper.sharedInstance.showMenuFor(
                message: message,
                in: self.view,
                from: button,
                with: self
            )
        }
    }
    
    func shouldCloseThread() {
        if let chatVCDelegate = chatVCDelegate {
            chatVCDelegate.shouldCloseThread()
        } else {
            guard let threadVC = threadVC else {
                return
            }
            
            removeChildVC(child: threadVC)
            
            self.threadVC = nil
            
            setMessageFieldActive()
        }
    }
    
    func shouldStartCallWith(link: String) {
        WindowsManager.sharedInstance.showCallWindow(link: link)
    }
}

extension NewChatViewController : MediaFullScreenDelegate {
    
    func shouldShowFullMediaFor(message: TransactionMessage) {
        goToMediaFullView(message: message)
    }
    
    func goToMediaFullView(message: TransactionMessage?) {
        if mediaFullScreenView == nil {
            mediaFullScreenView = MediaFullScreenView()
        }
        
        if let mediaFullScreenView = mediaFullScreenView, let message = message {
            view.addSubview(mediaFullScreenView)
            
            mediaFullScreenView.delegate = self
            mediaFullScreenView.constraintTo(view: view)
            mediaFullScreenView.showWith(message: message)
            mediaFullScreenView.isHidden = false
        }
    }
    
    func willDismissView() {
        if let mediaFullScreenView = mediaFullScreenView {
            mediaFullScreenView.removeFromSuperview()
            self.mediaFullScreenView = nil
        }
    }
}
