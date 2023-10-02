//
//  NewChatViewController+BottomTopBarsExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension NewChatViewController {
    func setMessageFieldActive() {
        chatBottomView.setMessageFieldActive()
    }
}

extension NewChatViewController : ChatHeaderViewDelegate {
    func didClickThreadsButton() {
        if let chatId = chat?.id {
            let threadsListVC = ThreadsListViewController.instantiate(
                chatId: chatId,
                windowSize: self.view.window?.frame.size
            )
          
            WindowsManager.sharedInstance.showNewWindow(
                with: "threads-list".localized,
                size: CGSize(width: 450, height: 700),
                centeredIn: self.view.window,
                identifier: "threads-list",
                contentVC: threadsListVC
            )
        }
    }
    
    func didClickWebAppButton() {
        WindowsManager.sharedInstance.showWebAppWindow(
            chat: chat,
            view: view
        )
    }
    
    func didClickMuteButton() {
        guard let chat = chat else {
            return
        }

        if chat.isPublicGroup() {
//            childVCContainer.showNotificaionLevelViewOn(
//                parentVC: self,
//                with: chat,
//                delegate: self
//            )
        } else {
            chatViewModel.toggleVolumeOn(
                chat: chat,
                completion: { chat in
                    if let chat = chat, chat.isMuted(){
                        self.messageBubbleHelper.showGenericMessageView(
                            text: "chat.muted.message".localized,
                            in: self.view,
                            delay: 2.5
                        )
                    }
                }
            )
        }
    }
    
    func didClickCallButton() {
        childViewControllerContainer.showCallOptionsMenuOn(
            parentVC: self,
            with: self.chat,
            delegate: self
        )
    }
    
    func didClickHeaderButton() {
        if let contact = contact {
            
            let contactVC = NewContactViewController.instantiate(contact: contact)
            
            WindowsManager.sharedInstance.showContactWindow(
                vc: contactVC,
                window: view.window,
                title: "contact".localized,
                identifier: "contact-window",
                size: CGSize(width: 414, height: 700)
            )
            
        } else if let chat = chat {
            
            let chatDetailsVC = GroupDetailsViewController.instantiate(
                chat: chat,
                delegate: self
            )
            
            WindowsManager.sharedInstance.showContactWindow(
                vc: chatDetailsVC,
                window: view.window,
                title: "group.details".localized,
                identifier: "chat-window",
                size: CGSize(width: 414, height: 600)
            )
        }
    }
}

extension NewChatViewController : GroupDetailsDelegate {
    func shouldExitTribeOrGroup(
        completion: @escaping () -> ()
    ) {
        
    }
}

extension NewChatViewController : ChatBottomViewDelegate {
    
    func getAttachmentObject(
        text: String,
        price: Int
    ) -> AttachmentObject? {
        if draggingView.isSendingMedia() {
            let attachmentObject = draggingView.getData(
                price: price,
                text: text
            )
            return attachmentObject
        } else {
            if let data = text.data(using: .utf8) {
                let (key, encryptedData) = SymmetricEncryptionManager.sharedInstance.encryptData(data: data)
                
                if let encryptedData = encryptedData {
                    let attachmentObject = AttachmentObject(
                        data: encryptedData,
                        mediaKey: key,
                        type: .Text,
                        text: nil,
                        paidMessage: text,
                        price: price
                    )
                    return attachmentObject
                }
            }
        }
        return nil
    }
    
    func shouldSendMessage(
        text: String,
        price: Int,
        completion: @escaping (Bool) -> ()
    ) {
        chatBottomView.resetReplyView()
        
        if shouldUploadMedia() {
            
            let attachmentObject = getAttachmentObject(
                text: text,
                price: price
            )
            
            draggingView.setup()
            
            if let attachmentObject = attachmentObject {
                chatBottomView.resetReplyView()
                
                newChatViewModel.insertPrivisionalAttachmentMessageAndUpload(
                    attachmentObject: attachmentObject, chat: chat
                )
            } else {
                messageBubbleHelper.showGenericMessageView(
                    text: "generic.error.message".localized, in: view
                )
            }
        } else if let text = giphyText(text: text), let data = draggingView.getMediaData() {
            
            draggingView.setup()
            
            newChatViewModel.shouldSendGiphyMessage(
                text: text,
                type: TransactionMessage.TransactionMessageType.message.rawValue,
                data: data,
                completion: { success in
                    completion(success)
                }
            )
        } else {
            newChatViewModel.shouldSendMessage(
                text: text,
                type: TransactionMessage.TransactionMessageType.message.rawValue,
                completion: { success in
                    completion(success)
                }
            )
        }
    }
    
    func giphyText(
        text: String
    ) -> String? {
        let (sendingGiphy, giphyObject) = draggingView.isSendingGiphy()
        
        if let giphyObject = giphyObject, sendingGiphy {
            
            return GiphyHelper.getMessageStringFrom(
                media: giphyObject,
                text: text
            )
        }
        
        return nil
    }
    
    func shouldUploadMedia() -> Bool {
        return draggingView.isSendingMedia() || chatBottomView.isPaidTextMessage()
    }
    
    func didClickAttachmentsButton() {
        guard let chat = chat else {
            return
        }
        
        if chat.isPublicGroup() {
            messageBubbleHelper.showGenericMessageView(
                text: "drag.attachment".localized,
                in: view,
                delay: 2.5
            )
        } else {
            childViewControllerContainer.showPmtOptionsMenuOn(
                parentVC: self,
                with: chat,
                delegate: self
            )
        }
    }
    
    func didClickGiphyButton() {
        let isAtBottom = isChatAtBottom()
        
        chatBottomView.loadGiphySearchWith(delegate: self)
        
        if isAtBottom {
            shouldScrollToBottom()
        }
    }
    
    func didClickMicButton() {
        newChatViewModel.shouldStartRecordingWith(delegate: self)
    }
    
    func didClickConfirmRecordingButton() {
        newChatViewModel.didClickConfirmRecordingButton()
    }
    
    func didClickCancelRecordingButton() {
        newChatViewModel.didClickCancelRecordingButton()
    }
    
    func didSelectSendPaymentMacro() {
        childViewControllerContainer.showPaymentModeWith(
            parentVC: self,
            with: chat,
            delegate: self,
            mode: .Send
        )
    }
    
    func didSelectReceivePaymentMacro() {
        childViewControllerContainer.showPaymentModeWith(
            parentVC: self,
            with: chat,
            delegate: self,
            mode: .Request
        )
    }
    
    func shouldUpdateMentionSuggestionsWith(_ object: [MentionOrMacroItem]) {
        chatMentionAutocompleteDataSource?.updateMentionSuggestions(
            suggestions: object
        )
    }
    
    func shouldGetSelectedMention() -> String? {
        return chatMentionAutocompleteDataSource?.getSelectedValue()
    }
    
    func shouldGetSelectedMacroAction() -> (() -> ())? {
        return chatMentionAutocompleteDataSource?.getSelectedAction()
    }
    
    func didTapUpArrow() -> Bool {
        chatMentionAutocompleteDataSource?.moveSelectionUp()
        return chatMentionAutocompleteDataSource?.isTableVisible() ?? false
    }
    
    func didTapDownArrow() -> Bool {
        chatMentionAutocompleteDataSource?.moveSelectionDown()
        return chatMentionAutocompleteDataSource?.isTableVisible() ?? false
    }
    
    func isChatAtBottom() -> Bool {
        return chatCollectionView.isAtBottom()
    }
    
    func shouldScrollToBottom() {
        chatCollectionView.scrollToBottom(animated: false)
    }
}

extension NewChatViewController : GiphySearchViewDelegate {
    func didSelectGiphy(object: GiphyObject, data: Data) {
        draggingView.showGiphyPreview(data: data, object: object)
    }
}

extension NewChatViewController : AudioHelperDelegate {
    func didStartRecording(_ success: Bool) {
        if success {
            chatBottomView.toggleRecordingViews(show: true)
        }
    }
    
    func didFinishRecording(_ success: Bool) {
        if success {
            newChatViewModel.didFinishRecording()
        }
        chatBottomView.toggleRecordingViews(show: false)
    }
    
    func audioTooShort() {
        messageBubbleHelper.showGenericMessageView(text: "audio.too.short".localized, in: self.view)
    }
    
    func recordingProgress(minutes: String, seconds: String) {
        chatBottomView.recordingProgress(minutes: minutes, seconds: seconds)
    }
    
    func permissionDenied() {
        chatBottomView.toggleRecordButton(enable: false)
    }
}

extension NewChatViewController : ActionsDelegate {
    func didCreateMessage(message: TransactionMessage) {}
    
    func didFailInvoiceOrPayment() {
        messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized, in: view)
    }
    
    func shouldCreateCall(mode: VideoCallHelper.CallMode) {
        let link = VideoCallHelper.createCallMessage(mode: mode)
        newChatViewModel.sendCallMessage(link: link)
    }
    
    func shouldSendPaymentFor(
        paymentObject: PaymentViewModel.PaymentObject,
        callback: ((Bool) -> ())?
    ) {
        newChatViewModel.shouldSendPaymentFor(
            paymentObject: paymentObject,
            callback: callback
        )
    }
    
    func shouldReloadMuteState() {}
}

extension NewChatViewController : NewMessagesIndicatorViewDelegate {
    func didTouchButton() {
        chatCollectionView.scrollToBottom()
    }
}
