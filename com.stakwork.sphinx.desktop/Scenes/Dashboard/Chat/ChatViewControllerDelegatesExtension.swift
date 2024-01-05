//
//  ChatViewControllerDelegatesExtension.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 15/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension ChatViewController : NSTextViewDelegate, MessageFieldDelegate {
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        if let replacementString = replacementString, replacementString == "\n" {
            if sendButton.isEnabled {
                shouldSendMessage()
            }
            return false
        }
        
        let currentString = textView.string as NSString
        let currentChangedString = currentString.replacingCharacters(in: affectedCharRange, with: replacementString ?? "")
        return (currentChangedString.count <= kCharacterLimit)
    }
    
    func textDidChange(_ notification: Notification) {
        chat?.setOngoingMessage(text: messageTextView.string)
        
        let didUpdateHeight = updateBottomBarHeight()
        if !didUpdateHeight {
            return
        }
        
        if chatCollectionView.shouldScrollToBottom() {
            chatCollectionView.scrollToBottom(animated: false)
        }
    }
    
    func updateBottomBarHeight() -> Bool {
        let messageFieldContentHeight = messageTextView.contentSize.height
        let maximumFieldHeight:CGFloat = 76
        let newFieldHeight = min(messageFieldContentHeight, maximumFieldHeight)
        
        if bottomBarHeightConstraint.constant == newFieldHeight + kBottomBarMargins {
            messageTextView.scrollRangeToVisible(NSMakeRange(messageTextView.string.length, 0))
            return false
        }
        
        bottomBarHeightConstraint.constant = newFieldHeight + kBottomBarMargins
        bottomBar.layoutSubtreeIfNeeded()
        
        messageTextView.scrollRangeToVisible(NSMakeRange(messageTextView.string.length, 0))
        return true
    }
    
    func shouldSendMessage() {
        if shouldUploadMedia() {
            uploadAndSend()
            return
        }
        
        let text = giphyText() ?? messageTextView.string.trim()
        sendMessageWith(text: text)
    }
    
    func shouldUploadMedia() -> Bool {
        return draggingView.isSendingMedia() || isPaidTextMessage()
    }
    
    func giphyText() -> String? {
        let text = messageTextView.string.trim()
        let (sendingGiphy, giphyObject) = draggingView.isSendingGiphy()
        
        if let giphyObject = giphyObject, sendingGiphy {
            draggingView.setup()
            return GiphyHelper.getMessageStringFrom(media: giphyObject, text: text)
        }
        return nil
    }
    
    func sendMessageWith(text: String) {
        var messageText = text
        
        if messageText.isEmpty {
           return
        }
        
        if let podcastComment = messageReplyView.getReplyingPodcast() {
            messageText = podcastComment.getJsonString(withComment: text) ?? text
        }
        
        let (botAmount, wrongAmount) = isWrongBotCommandAmount(text: messageText)
        if wrongAmount {
            return
        }
        
        let messageType = TransactionMessage.TransactionMessageType.message.rawValue
        let _ = createProvisionalAndSend(messageText: messageText, type: messageType, botAmount: botAmount)
        hideMessageReplyView()
        resetMessageField()
    }
    
    func isWrongBotCommandAmount(text: String) -> (Int, Bool) {
        let (botAmount, failureMessage) = GroupsManager.sharedInstance.calculateBotPrice(chat: chat, text: text)
        if let failureMessage = failureMessage {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: failureMessage)
            return (botAmount, true)
        }
        return (botAmount, false)
    }
    
    func createProvisionalAndSend(messageText: String, type: Int, botAmount: Int) -> TransactionMessage? {
        let provisionalMessage = insertPrivisionalMessage(text: messageText, type: type, chat: chat)
        sendMessage(provisionalMessage: provisionalMessage, text: messageText, botAmount: botAmount)
        return provisionalMessage
    }
    
    func sendMessage(provisionalMessage: TransactionMessage?, text: String, botAmount: Int = 0) {
        let messageType = TransactionMessage.TransactionMessageType(fromRawValue: provisionalMessage?.type ?? 0)
        guard let params = TransactionMessage.getMessageParams(contact: contact, chat: chat, type: messageType, text: text, botAmount: botAmount, replyingMessage: messageReplyView.getReplyingMessage()) else {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.didFailSendingMessage(provisionalMessage: provisionalMessage)
            })
            return
        }
        sendMessage(provisionalMessage: provisionalMessage, params: params)
    }
    
    func sendMessage(provisionalMessage: TransactionMessage?, params: [String: AnyObject]) {
        API.sharedInstance.sendMessage(params: params, callback: { m in
            if let message = TransactionMessage.insertMessage(m: m).0 {
                message.setPaymentInvoiceAsPaid()
                self.insertSentMessage(message: message)
            }
        }, errorCallback: {
             if let provisionalMessage = provisionalMessage {
                provisionalMessage.status = TransactionMessage.TransactionMessageStatus.failed.rawValue
                provisionalMessage.saveMessage()
                self.insertSentMessage(message: provisionalMessage)
             }
        })
    }
    
    func insertPrivisionalMessage(text: String, type: Int, chat: Chat?) -> TransactionMessage? {
        let message = TransactionMessage.createProvisionalMessage(messageContent: text, type: type, date: Date(), chat: chat, replyUUID: messageReplyView.getReplyingMessage()?.uuid)
        
        if let message = message {
            chatDataSource?.addMessageAndReload(message: message, provisional: true)
        }
        return message
    }
    
    func insertSentMessage(message: TransactionMessage) {
        updateViewChat(updatedChat: chat ?? contact?.getConversation())
        enableViewAndComplete()
        chatDataSource?.addMessageAndReload(message: message)
        delegate?.shouldReloadChatList()
    }
    
    func resetMessageField() {
        sendButton.isEnabled = false
        priceTextField.isEditable = false
        
        messageTextView.string = ""
        priceTextField.stringValue = ""
        chat?.resetOngoingMessage()
        let _ = updateBottomBarHeight()
        updatePriceFieldWidth()
        
        view.window?.makeFirstResponder(messageTextView)
    }
    
    func enableViewAndComplete() {
        sendButton.isEnabled = true
        messageTextView.isEditable = chat?.isStatusApproved() ?? true
        priceTextField.isEditable = true
    }
    
    func showErrorAlert() {
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
    }
    
    func forceKeysExchange(contactId: Int) {
        contactsService.exchangeKeys(id: contactId)
    }
}

extension ChatViewController : NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        updatePriceFieldWidth()
    }
    
    func updatePriceFieldWidth() {
        let currentString = (priceTextField?.stringValue ?? "")
        let width = NSTextField().getStringSize(text: currentString, font: NSFont.systemFont(ofSize: 15, weight: .semibold)).width
        priceTextFieldWidth.constant = (width < (kMinimumPriceFieldWidth - kPriceFieldPadding)) ? kMinimumPriceFieldWidth : width + kPriceFieldPadding
        priceTextField.superview?.layoutSubtreeIfNeeded()
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            if sendButton.isEnabled {
                shouldSendMessage()
            }
            return true
        }
        return false
    }
}

extension ChatViewController : ChatDataSourceDelegate {
    func didScrollToBottom() {
        unseenMessagesCount = 0
        scrollDownLabel.stringValue = "+1"
        scrollDownContainer.isHidden = true
    }
    
    func didFinishLoading() {
        DelayPerformedHelper.performAfterDelay(seconds: 0.1, completion: {
            self.chatCollectionView.alphaValue = 1.0
        })
    }
    
    func didDeleteGroup() {
        NotificationCenter.default.post(name: .shouldUpdateDashboard, object: nil)
        NotificationCenter.default.post(name: .shouldResetChat, object: nil)
    }
    
    func chatUpdated(chat: Chat) {
        updateViewChat(updatedChat: chat)
        messageBubbleHelper.hideLoadingWheel()
    }
}

extension ChatViewController : MessageCellDelegate {
    func didTapPayButton(transactionMessage: TransactionMessage, item: NSCollectionViewItem) {
        guard let invoice = transactionMessage.invoice else {
            return
        }
        
        let parameters: [String : AnyObject] = ["payment_request" : invoice as AnyObject]

        API.sharedInstance.payInvoice(parameters: parameters, callback: { payment in
            if let message = TransactionMessage.insertMessage(m: payment).0 {
                message.setPaymentInvoiceAsPaid()
                self.reloadMessages(newMessageCount: 1)
            }
        }, errorCallback: {
            if let indexPath = self.chatCollectionView.indexPath(for: item) {
                self.chatCollectionView.reloadItems(at: [indexPath])
            }
            self.showErrorAlert()
        })
    }
    
    func didTapAttachmentRow(message: TransactionMessage) {
        shouldShowFullMediaFor(message: message)
    }
    
    func didTapAttachmentCancel(transactionMessage: TransactionMessage) {
        enableViewAndComplete()
        AttachmentsManager.sharedInstance.cancelUpload()
        chatDataSource?.deleteCellFor(m: transactionMessage)
        CoreDataManager.sharedManager.deleteObject(object: transactionMessage)
    }
    
    func shouldShowFullMediaFor(message: TransactionMessage? = nil) {
        if draggingView.isSendingMedia() {
            return
        }
        
        if let message = message {
            delegate?.shouldShowFullMediaFor(message: message)
        }
    }
    
    func shouldStartCall(link: String, audioOnly: Bool) {
        var callUrl = link
        
        if audioOnly && !link.contains("startAudioOnly") {
            callUrl = "\(link)#config.startAudioOnly=true"
        }
        
        if let url = URL(string: callUrl) {
            NSWorkspace.shared.open(url)
        }
    }
    
    func didTapPayAttachment(transactionMessage: TransactionMessage) {
        let attachmentsManager = AttachmentsManager.sharedInstance
        attachmentsManager.payAttachment(message: transactionMessage, chat: chat, callback: { purchaseMessage in
            if let purchaseMessage = purchaseMessage {
                let _ = self.chatDataSource?.reloadAttachmentRow(m: purchaseMessage)
            } else {
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            }
        })
    }
    
    func shouldReload(item: NSCollectionViewItem) {
        if let indexPath = chatCollectionView.indexPath(for: item) {
            chatCollectionView.reloadItems(at: [indexPath])
            shouldScrollToBottom()
        }
    }
    
    func shouldScrollTo(message: TransactionMessage) {
        chatDataSource?.scrollTo(message: message)
    }
    
    func shouldScrollToBottom() {
        if chatCollectionView.shouldScrollToBottom() {
            chatCollectionView.scrollToBottom(animated: false)
        }
    }
    
    func shouldShowOptionsFor(message: TransactionMessage, from button: NSButton) {
        messageOptionsHelper.showMenuFor(message: message, in: self.view, from: button, with: self)
    }
    
    func toggleMessageReplyView() {
        messageReplyViewHeight.constant = messageReplyView.getViewHeight()
        toggleSearchTopView()
    }
    
    func hideMessageReplyView() {
        messageReplyView.resetObjects()
        messageReplyView.isHidden = true
        toggleMessageReplyView()
    }
    
    func toggleGiphySearchView() {
        toggleSearchTopView()
    }
    
    func hideGiphySearchView() {
        giphySearchView.isHidden = true
        toggleGiphySearchView()
    }
    
    func toggleSearchTopView() {
        let viewHeight = messageReplyView.getViewHeight() + giphySearchView.getViewHeight()
        if (viewHeight == 0) { bottomBar.addShadow(location: VerticalLocation.top, color: NSColor.black, opacity: 0.3, radius: 5.0) }
        self.searchTopViewHeight.constant = viewHeight
        self.searchTopView.layoutSubtreeIfNeeded()
        if self.chatCollectionView.shouldScrollToBottom() { self.chatCollectionView.scrollToBottom(animated: false) }
    }
}

extension ChatViewController : SearchTopViewDelegate {
    func didCloseReplyView() {
        toggleMessageReplyView()
    }
    
    func didCloseGiphyView() {
        toggleGiphySearchView()
    }
    
    func didSelectGiphy(object: GiphyObject, data: Data) {
        draggingView.showGiphyPreview(data: data, object: object)
    }
}

// Chat reply extension:

extension ChatViewController : MessageOptionsDelegate {
    func shouldDeleteMessage(message: TransactionMessage) {
        if message.id < 0 {
            chatDataSource?.deleteCellFor(m: message)
            CoreDataManager.sharedManager.deleteObject(object: message)
            return
        }
        
        chatViewModel.shouldDeleteMessage(message: message, completion: { (success, updatedMessage) in
            if success {
                self.chatDataSource?.updateDeletedMessage(m: updatedMessage ?? message)
            } else {
                self.messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized, in: self.view)
            }
        })
    }
    
    func shouldBoostMessage(message: TransactionMessage) {
        guard let params = TransactionMessage.getBoostMessageParams(contact: contact, chat: chat, replyingMessage: message) else {
            return
        }
        sendMessage(provisionalMessage: nil, params: params)
    }
    
    // logic to reply a message
    
    func shouldReplyToMessage(message: TransactionMessage) {
        if replyableMessages.isEmpty {
            replyableMessages.append(message)
        } else {
            replyableMessages.forEach { msg in
                if msg.chat?.id != chat?.id {
                    replyableMessages.append(message)
                } else if msg.chat?.id == chat?.id {
                    replyableMessages.removeAll(where: {$0.chat?.id == chat?.id})
                    replyableMessages.append(message)
                }
                    
            }
        }
        
        bottomBar.removeShadow()
        messageReplyView.configureForKeyboard(with: message, and: self)
        willReplay()
    }
    
    func updateMessageReplyView(message: TransactionMessage) {
        bottomBar.removeShadow()
        messageReplyView.configureForKeyboard(with: message, and: self)
        willReplay()
    }
 
    func willReplay() {
        toggleMessageReplyView()
        if chatCollectionView.shouldScrollToBottom() { chatCollectionView.scrollToBottom(animated: false) }
        view.window?.makeFirstResponder(messageTextView)
    }
    
    func shouldPerformChatAction(action: TransactionMessage.MessageActionsItem) {}
}

extension ChatViewController : GroupDetailsDelegate {
    func shouldExitTribeOrGroup(completion: @escaping () -> ()) {
        exitAndDeleteGroup(completion: {
            completion()
        })
    }
}
