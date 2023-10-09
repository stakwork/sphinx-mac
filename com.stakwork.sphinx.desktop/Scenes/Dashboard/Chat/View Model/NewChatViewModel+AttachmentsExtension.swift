//
//  NewChatViewModel+AttachmentsExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 19/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension NewChatViewModel: AttachmentsManagerDelegate {
    
    func insertPrivisionalAttachmentMessageAndUpload(
        attachmentObject: AttachmentObject,
        chat: Chat?,
        audioDuration: Double? = nil
    ) {
        let attachmentsManager = AttachmentsManager.sharedInstance

        chatDataSource?.setMediaDataForMessageWith(
            messageId: TransactionMessage.getProvisionalMessageId(),
            mediaData: MessageTableCellState.MediaData(
                image: attachmentObject.image,
                data: attachmentObject.getDecryptedData(),
                fileInfo: attachmentObject.getFileInfo(),
                audioInfo: attachmentObject.getAudioInfo(duration: audioDuration),
                failed: false
            )
        )

        if let message = TransactionMessage.createProvisionalAttachmentMessage(
            attachmentObject: attachmentObject,
            date: Date(),
            chat: chat,
            replyUUID: replyingTo?.uuid,
            threadUUID: threadUUID ?? replyingTo?.threadUUID ?? replyingTo?.uuid
        ) {
            attachmentsManager.setData(
                delegate: self,
                contact: contact,
                chat: chat,
                provisionalMessage: message
            )

            chatDataSource?.setProgressForProvisional(messageId: message.id, progress: 0)

            attachmentsManager.uploadAndSendAttachment(
                attachmentObject: attachmentObject,
                replyingMessage: replyingTo,
                threadUUID: replyingTo?.threadUUID ?? replyingTo?.uuid
            )
        }

        resetReply()
    }
    
    func shouldReplaceMediaDataFor(provisionalMessageId: Int, and messageId: Int) {
        chatDataSource?.replaceMediaDataForMessageWith(
            provisionalMessageId: provisionalMessageId,
            toMessageWith: messageId
        )
    }
    
    func didFailSendingMessage(
        provisionalMessage: TransactionMessage?
    ) {
        if let provisionalMessage = provisionalMessage {
            CoreDataManager.sharedManager.deleteObject(object: provisionalMessage)
            
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
        }
    }
    
    func didUpdateUploadProgress(progress: Int) {
        chatDataSource?.setProgressForProvisional(messageId: -1, progress: progress)
    }
    
    func didSuccessSendingAttachment(message: TransactionMessage, image: NSImage?) {
        insertSentMessage(
            message: message,
            chat: message.chat,
            completion: { (_, _) in }
        )
    }
}

extension NewChatViewModel {
    func didClickConfirmRecordingButton() {
        audioRecorderHelper.shouldFinishRecording()
    }
    
    func didClickCancelRecordingButton() {
        audioRecorderHelper.shouldCancelRecording()
    }
    
    func shouldStartRecordingWith(
        delegate: AudioHelperDelegate
    ) {
        audioRecorderHelper.configureAudioSession(delegate: delegate)
        audioRecorderHelper.shouldStartRecording()
    }
    
    func shouldStopAndSendAudio() {
        audioRecorderHelper.shouldFinishRecording()
    }
    
    func shouldCancelRecording() {
        audioRecorderHelper.shouldCancelRecording()
    }
    
    func didFinishRecording() {
        let audioData = audioRecorderHelper.getAudioDataAndDuration()

        if let data = audioData.0 {
            let (key, encryptedData) = SymmetricEncryptionManager.sharedInstance.encryptData(data: data)

            if let encryptedData = encryptedData {

                let attachmentObject = AttachmentObject(
                    data: encryptedData,
                    mediaKey: key,
                    type: AttachmentsManager.AttachmentType.Audio
                )

                insertPrivisionalAttachmentMessageAndUpload(
                    attachmentObject: attachmentObject,
                    chat: chat,
                    audioDuration: audioData.1
                )
            }
        }
    }
}

extension NewChatViewModel {
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
        
        sendMessage(provisionalMessage: nil, params: params, completion: { (success, _) in
            callback?(success)
        })
    }
}
