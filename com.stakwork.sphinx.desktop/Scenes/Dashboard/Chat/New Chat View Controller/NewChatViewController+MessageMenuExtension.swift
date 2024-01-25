//
//  NewChatViewController+MessageMenuExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension NewChatViewController : MessageOptionsDelegate {
    func shouldShowThreadFor(message: TransactionMessage) {
        if let threadUUID = message.threadUUID {
            self.showThread(threadID: threadUUID)
        } else if let uuid = message.uuid {
            self.showThread(threadID: uuid)
        }
    }
    
    func shouldDeleteMessage(message: TransactionMessage) {
        newChatViewModel.shouldDeleteMessage(message: message)
    }
    
    func shouldResendMessage(message:TransactionMessage) {
        newChatViewModel.shouldResendMessage(message: message)
    }
    
    func shouldBoostMessage(message: TransactionMessage) {
        newChatViewModel.shouldBoostMessage(message: message)
    }
    
    func shouldTogglePinState(message: TransactionMessage, pin: Bool) {
        newChatViewModel.shouldTogglePinState(
            message: message,
            pin: pin
        ) { success in
            if success {
                self.configurePinnedMessageView()
                self.showPinStatePopupFor(mode: pin ? .MessagePinned : .MessageUnpinned)
            } else {
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            }
        }
    }
}

extension NewChatViewController : NewMessageReplyViewDelegate {
    func didCloseReplyView() {
        newChatViewModel.resetReply()
        chatBottomView.resetReplyView()
        ChatTrackingHandler.shared.deleteReplyableMessage(with: chat?.id)
    }
}
