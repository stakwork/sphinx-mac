//
//  ChatViewControllerRecordingExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 03/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension ChatViewController {
    func didClickRecordingButton(_ sender: NSButton) {
        switch(sender.tag) {
        case RecordingButton.Cancel.rawValue:
            audioRecorderHelper.shouldCancelRecording()
            break
        case RecordingButton.Confirm.rawValue:
            audioRecorderHelper.shouldFinishRecording()
            break
        default:
            break
        }
    }
    
    func prepareRecordingView() {
        audioRecorderHelper.configureAudioSession(delegate: self)
        recordingRedCircle.configureForRecording()
        
        recordingConfirmButtonContainer.wantsLayer = true
        recordingConfirmButtonContainer.layer?.cornerRadius = recordingConfirmButtonContainer.frame.height / 2
        
        recordingCancelButtonContainer.wantsLayer = true
        recordingCancelButtonContainer.layer?.cornerRadius = recordingCancelButtonContainer.frame.height / 2
    }
    
    func toggleRecordButton(enable: Bool) {
        micButton.isEnabled = enable
        micButton.alphaValue = enable ? 1.0 : 0.7
        micButton.cursor = enable ? .pointingHand : .arrow
    }
    
    func toggleControls(enable: Bool) {
        emojiButton.isEnabled = enable
        giphyButton.isEnabled = enable
        emojiButton.alphaValue = enable ? 1.0 : 0.7
        giphyButton.alphaValue = enable ? 1.0 : 0.7
        emojiButton.cursor = enable ? .pointingHand : .arrow
        giphyButton.cursor = enable ? .pointingHand : .arrow
        
        messageTextView.isEditable = enable
        priceTextField.isEditable = enable
        
        attachmentsButton.isEnabled = enable
        sendButton.isEnabled = enable
    }
    
    func shouldStartRecording() {
        recordingTimeLabel.stringValue = "0:00"
        audioRecorderHelper.shouldStartRecording()
    }
    
    func toggleRecordingViews(show: Bool) {
        recordingRedCircle.toggleAnimation(animate: show)
        recordingContainer.isHidden = !show
    }
}

extension ChatViewController : AudioHelperDelegate {
    func permissionDenied() {
        toggleRecordButton(enable: false)
    }
    
    func didStartRecording(_ success: Bool) {
        if success {
            toggleRecordingViews(show: true)
        }
    }
    
    func didFinishRecording(_ success: Bool) {
        if success {
            if let audio = audioRecorderHelper.getAudioData() {
                print(audio)
                let (key, encryptedData) = SymmetricEncryptionManager.sharedInstance.encryptData(data: audio)
                if let encryptedData = encryptedData {
                    let attachmentObject = AttachmentObject(data: encryptedData, mediaKey: key, type: AttachmentsManager.AttachmentType.Audio)
                    shouldStartUploading(attachmentObject: attachmentObject)
                }
            }
        }
        
        toggleRecordingViews(show: false)
    }
    
    func audioTooShort() {
        messageBubbleHelper.showGenericMessageView(text: "audio.too.short".localized, in: self.view)
    }
    
    func recordingProgress(minutes: String, seconds: String) {
        recordingTimeLabel.stringValue = "\(minutes):\(seconds)"
    }
}

extension ChatViewController : AttachmentsManagerDelegate {
    func isPaidTextMessage() -> Bool {
        let price = Int(priceTextField.stringValue) ?? 0
        let text = messageTextView.string.trim()
        return price > 0 && !text.isEmpty
    }
    
    func getAttachmentObject() -> AttachmentObject? {
        let text = messageTextView.string
        let price = Int(priceTextField.stringValue) ?? 0
        
        if draggingView.isSendingMedia() {
            let attachmentObject = draggingView.getData(price: price, text: text)
            return attachmentObject
        } else {
            if let data = text.data(using: .utf8) {
                let (key, encryptedData) = SymmetricEncryptionManager.sharedInstance.encryptData(data: data)
                
                if let encryptedData = encryptedData {
                    let attachmentObject = AttachmentObject(data: encryptedData, mediaKey: key, type: .Text, text: nil, paidMessage: text, price: price)
                    return attachmentObject
                }
            }
        }
        return nil
    }
    
    func uploadAndSend() {
        let attachmentObject = getAttachmentObject()
        draggingView.setup()
        
        if let attachmentObject = attachmentObject {
            resetMessageField()
            shouldStartUploading(attachmentObject: attachmentObject)
        } else {
            messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized, in: view)
        }
    }
    
    func shouldStartUploading(attachmentObject: AttachmentObject) {
        insertPrivisionalAttachmentMessageAndUpload(attachmentObject: attachmentObject, chat: chat)
    }
    
    func insertPrivisionalAttachmentMessageAndUpload(
        attachmentObject: AttachmentObject,
        chat: Chat?
    ) {
        let replyingToMessage = messageReplyView.getReplyingMessage()
        
        if let message = TransactionMessage.createProvisionalAttachmentMessage(
            attachmentObject: attachmentObject,
            date: Date(),
            chat: chat,
            replyUUID: replyingToMessage?.uuid,
            threadUUID: replyingToMessage?.threadUUID ?? replyingToMessage?.uuid
        ) {
            chatDataSource?.addMessageAndReload(message: message, provisional: true)
            
            attachmentsManager.setData(
                delegate: self,
                contact: contact,
                chat: chat,
                provisionalMessage: message
            )
            
            attachmentsManager.uploadAndSendAttachment(
                attachmentObject: attachmentObject,
                replyingMessage: replyingToMessage,
                threadUUID: replyingToMessage?.threadUUID ?? replyingToMessage?.uuid
            )
            
            hideMessageReplyView()
        }
    }
    
    func didFailSendingMessage(provisionalMessage: TransactionMessage?) {
        if let provisionalMessage = provisionalMessage {
            chatDataSource?.deleteCellFor(m: provisionalMessage)
            CoreDataManager.sharedManager.deleteObject(object: provisionalMessage)
            
            let errorMessage = provisionalMessage.isTextMessage() ? "generic.message.error" : "generic.error.message"
            AlertHelper.showAlert(title: "generic.error.title".localized, message: errorMessage.localized)
        }
        toggleControls(enable: true)
    }
    
    func didUpdateUploadProgress(progress: Int) {
        for item in chatCollectionView.visibleItems() {
            if let item = item as? MediaUploadingProtocol, item.isUploading() {
                item.configureUploadingProgress(progress: progress, finishUpload: (progress >= 100))
            }
        }
    }
    
    func didSuccessSendingAttachment(message: TransactionMessage, image: NSImage?) {
        insertSentMessage(message: message)
    }
}

extension ChatViewController : ActionsDelegate {
    func didCreateMessage(message: TransactionMessage) {
        chatDataSource?.addMessageAndReload(message: message)
    }
    
    func didFailInvoiceOrPayment() {
        messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized, in: view)
    }
    
    func shouldCreateCall(mode: VideoCallHelper.CallMode) {
        let link = VideoCallHelper.createCallMessage(mode: mode)
        
        let type = (self.chat?.isGroup() == false) ?
        TransactionMessage.TransactionMessageType.call.rawValue :
        TransactionMessage.TransactionMessageType.message.rawValue
        
        var messageText = link
        
        if type == TransactionMessage.TransactionMessageType.call.rawValue {
            
            let voipRequestMessage = VoIPRequestMessage()
            voipRequestMessage.recurring = false
            voipRequestMessage.link = link
            voipRequestMessage.cron = ""
            
            messageText = voipRequestMessage.getCallLinkMessage() ?? link
        }
        
        sendMessageWith(
            text: messageText,
            type: type
        )
    }
    
    func shouldSendPaymentFor(
        paymentObject: PaymentViewModel.PaymentObject,
        callback: ((Bool) -> ())?
    ) {
        guard let messageUUID = paymentObject.transactionMessage?.uuid else {
            return
        }
        
        guard let amount = paymentObject.amount, amount > 0 else {
            return
        }
        
        guard let params = TransactionMessage.getTribePaymentParams(
            chat: chat,
            messageUUID: messageUUID,
            amount: amount,
            text: paymentObject.message ?? ""
        ) else {
            callback?(false)
            return
        }
        sendMessage(provisionalMessage: nil, params: params, completion: { success in
            callback?(success)
        })
    }
    
    func shouldReloadMuteState() {
        setVolumeState()
    }
}
