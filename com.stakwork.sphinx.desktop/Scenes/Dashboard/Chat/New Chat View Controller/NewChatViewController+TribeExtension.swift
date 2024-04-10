//
//  NewChatViewController+TribeExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension NewChatViewController {
    
    func fetchTribeData() {
        configurePinnedMessageView()
        
        if chat?.isPublicGroup() == false {
            return
        }

        chat?.updateTribeInfo() {
            self.chatTopView.updateViewOnTribeFetch()
            self.addPodcastVC(deepLinkData: self.deepLinkData) 
            self.configurePinnedMessageView()
        }
    }
    
    ///Pinned Message
    func configurePinnedMessageView() {
        if isThread {
            return
        }
        
        if let chatId = chat?.id {
            chatTopView.configurePinnedMessageViewWith(
                chatId: chatId,
                andDelegate: self
            ) {
//                self.shouldAdjustTableViewTopInset()
            }
        }
    }
    
    func showPendingApprovalMessage() {
        if chat?.isStatusPending() ?? false {
            messageBubbleHelper.showGenericMessageView(text: "waiting.admin.approval".localized)
        }
    }
}

extension NewChatViewController : PinnedMessageViewDelegate {
    
    func shouldTogglePinState(
        messageId: Int,
        pin: Bool
    ) {
        guard let chat = self.chat else {
            return
        }
        
        guard let message = TransactionMessage.getMessageWith(id: messageId) else {
            return
        }
        
        API.sharedInstance.pinChatMessage(
            messageUUID: (pin ? message.uuid : "_"),
            chatId: chat.id,
            callback: { pinnedMessageUUID in
                self.chat?.pinnedMessageUUID = pinnedMessageUUID
                self.chat?.saveChat()
                
                self.configurePinnedMessageView()
                self.showPinStatePopupFor(mode: pin ? .MessagePinned : .MessageUnpinned)
            },
            errorCallback: {
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            }
        )
    }
    
    func showPinStatePopupFor(
        mode: PinNotificationView.ViewMode
    ) {
        pinMessageNotificationView.configureFor(
            mode: mode
        )
    }
    
    func didTapUnpinButtonFor(messageId: Int) {
        shouldTogglePinState(
            messageId: messageId,
            pin: false
        )
    }
    
    func didTapPinBarViewFor(messageId: Int) {
        pinMessageDetailView.configureWith(
            messageId: messageId,
            delegate: self
        )
    }
    
    func shouldNavigateTo(messageId: Int) {
        chatTableDataSource?.reloadWith(pinnedMessageId: messageId)
    }
}
