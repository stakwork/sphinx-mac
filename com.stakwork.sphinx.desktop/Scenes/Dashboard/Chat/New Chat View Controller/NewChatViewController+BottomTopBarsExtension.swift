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
//        messageTextView.window?.makeFirstResponder(nil)
//        childVCContainer.showCallOptionsMenuOn(parentVC: self, with: self.chat, delegate: self)
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
        chatBottomView.loadGiphySearchWith(delegate: self)
    }
    
    func didClickSendButton() {
        
    }
    
    func didClickMicButton() {
        
    }
    
    func didClickConfirmRecordingButton() {
        
    }
    
    func didClickCancelRecordingButton() {
        
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
}

extension NewChatViewController : GiphySearchViewDelegate {
    func didSelectGiphy(object: GiphyObject, data: Data) {
        
    }
}

extension NewChatViewController : ActionsDelegate {
    func didCreateMessage(message: TransactionMessage) {
        
    }
    
    func didFailInvoiceOrPayment() {
        
    }
    
    func shouldCreateCall(mode: VideoCallHelper.CallMode) {
        
    }
    
    func shouldSendPaymentFor(
        paymentObject: PaymentViewModel.PaymentObject,
        callback: ((Bool) -> ())?
    ) {
        
    }
    
    func shouldReloadMuteState() {
        
    }
}
