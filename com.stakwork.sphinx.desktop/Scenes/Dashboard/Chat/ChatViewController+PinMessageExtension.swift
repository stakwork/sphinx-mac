//
//  ChatViewController+PinMessageExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 24/05/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension ChatViewController: PinnedMessageViewDelegate {
    
    func configurePinnedMessageView() {
        guard let pinnedMessageUUID = chat?.pinnedMessageUUID, !pinnedMessageUUID.isEmpty else {
            pinMessageBarView.hideView()
            return
        }
        
        if let chatId = chat?.id {
            
            pinMessageBarView.configureWith(
                chatId: chatId,
                and: self
            ) {
                self.pinMessageBarViewHeightConstraint.constant = 50
                self.pinMessageBarView.superview?.layoutSubtreeIfNeeded()
            }
        }
    }
    
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
            messageUUID: (pin ? message.uuid : ""),
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
        pinNotificationView.configureFor(mode: mode)
    }
    
    func didTapUnpinButtonFor(
        messageId: Int
    ) {
        shouldTogglePinState(
            messageId: messageId,
            pin: false
        )
    }
    
    func didTapPinBarViewFor(
        messageId: Int
    ) {
        pinMessageDetailView.configureWith(
            messageId: messageId,
            delegate: self
        )
    }
}
