//
//  NewChatViewController+CollectionViewExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

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
//            chatBottomView.messageFieldView.childViewControllerContainer.showTribeMemberPopupViewOn(parentVC: self, with: message, delegate: self)
            chatBottomView.messageFieldView.childViewControllerContainer.configureDataSource(delegate: self)
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
    
    func finalizeInvoicePayment(message:TransactionMessage){
        guard let invoice = message.invoice else {
            return
        }
        let parameters: [String : AnyObject] = ["payment_request" : invoice as AnyObject]
        API.sharedInstance.payInvoice(parameters: parameters, callback: { payment in
            if let message = TransactionMessage.insertMessage(m: payment).0 {
                message.setPaymentInvoiceAsPaid()
                self.chatTableDataSource?.reloadAllVisibleRows()
            }
        }, errorCallback: {_ in
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            self.chatTableDataSource?.reloadAllVisibleRows()
        })
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

extension NewChatViewController: NewMenuItemDataSourceDelegate {
    func itemSelected(at index: Int) {
        chatBottomView.messageFieldView.childViewControllerContainer.isHidden = true
        switch index {
        case 0:
            self.draggingView.openFileExplorer()
        default:
            break
        }
    }
}

extension NewChatViewController: AddAttachmentDelegate {
    func addAttachmentClicked() {
        draggingView.openFileExplorer()
    }
}

extension NewChatViewController: ShowPreviewDelegate {
    func showImagePreview(data: Data, image: NSImage, fileName: String) {
        showPreview(data: data, image: image, type: .Photo, fileName: fileName)
    }
    
    func showPDFPreview(data: Data, image: NSImage, url: URL, fileName: String) {
        showVideoFilePreview(data: data, type: .PDF, url: url, fileName: fileName)
    }
    
    func showGIFPreview(data: Data, image: NSImage?, fileName: String) {
        if let image {
            showPreview(data: data, image: image, type: .Gif, fileName: fileName)
        }
    }
    
    func showVideoPreview(data: Data, url: URL, fileName: String) {
        showVideoFilePreview(data: data, type: .Video, url: url, fileName: fileName)
    }
    
    func showFilePreview(data: Data, url: URL, fileName: String) {
        showVideoFilePreview(data: data, type: .GenericFile, url: url, fileName: fileName)
    }
    
    func showGiphyPreview(data: Data, object: GiphyObject, fileName: String) {
        
    }
    
    func showPreview(data: Data, image: NSImage, type: AttachmentsManager.AttachmentType, fileName: String) {
        if chatBottomView.messageFieldView.fileDroppedCounter <= totalFileDroppable {
            chatBottomView.messageFieldView.fileDroppedCounter += 1
            let newItem = NewAttachmentItem(previewImage: image, previewType: type, previewData: data)
            let currentItems = chatBottomView.messageFieldView.newChatAttachmentView.menuItems + [newItem]
            updateAddButton(currentItems: currentItems, hasText: !chatBottomView.messageFieldView.messageTextView.string.isEmpty)
            chatBottomView.messageFieldView.newChatAttachmentView.updateCollectionView(menuItems: currentItems)
            draggingView.resetView()
            chatBottomView.messageFieldView.newChatAttachmentView.isHidden = false
            let mediaInfo = MediaObjectInfo(mediaData: data, mediaType: type, fileName: fileName, image: image)
            chatBottomView.messageFieldView.newChatAttachmentView.allMediaData.append(mediaInfo)
            _ = chatBottomView.messageFieldView.updateBottomBarHeight()
        } else {
            AlertHelper.showAlert(title: "Failed To Upload", message: "Unable to attach the file")
            draggingView.resetView()
        }
        chatBottomView.messageFieldView.updateChatBottomView()
    }
    
    func showVideoFilePreview(data: Data, image: NSImage? = nil, type: AttachmentsManager.AttachmentType, url: URL, fileName: String) {
        
        if chatBottomView.messageFieldView.fileDroppedCounter <= totalFileDroppable {
            chatBottomView.messageFieldView.fileDroppedCounter += 1
            let newItem = NewAttachmentItem(previewImage: NSImage(data: data) ?? NSImage(), previewType: type, previewData: data, previewURL: url)
            let currentItems = chatBottomView.messageFieldView.newChatAttachmentView.menuItems + [newItem]
            updateAddButton(currentItems: currentItems, hasText: !chatBottomView.messageFieldView.messageTextView.string.isEmpty)
            chatBottomView.messageFieldView.newChatAttachmentView.updateCollectionView(menuItems: currentItems)
            draggingView.resetView()
            chatBottomView.messageFieldView.newChatAttachmentView.isHidden = false
            let mediaInfo = MediaObjectInfo(mediaData: data, mediaType: type, fileName: fileName, image: image)
            chatBottomView.messageFieldView.newChatAttachmentView.allMediaData.append(mediaInfo)
            _ = chatBottomView.messageFieldView.updateBottomBarHeight()
        } else {
            AlertHelper.showAlert(title: "Failed To Upload", message: "Unable to attach the file")
            draggingView.resetView()
        }
        chatBottomView.messageFieldView.updateChatBottomView()
    }
    
    func updateAddButton(currentItems: [NewAttachmentItem], hasText: Bool = true) {
        let leadingConstant = chatBottomView.messageFieldView.frame.width - CGFloat((currentItems.count * 140)) - 110 - CGFloat((currentItems.count - 1) * 14)
        if (leadingConstant > 170) {
            chatBottomView.messageFieldView.newChatAttachmentView.addButtonLeadingConstraint.constant = -(leadingConstant - 140)
        } else {
            chatBottomView.messageFieldView.newChatAttachmentView.addButtonLeadingConstraint.constant = -62
        }
        
    }
}
