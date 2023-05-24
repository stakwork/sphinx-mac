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
    
    func didTapUnpinButtonFor(messageId: Int) {
        
    }
    
    func didTapPinBarViewFor(messageId: Int) {
        pinMessageDetailView.configureWith(
            messageId: messageId,
            delegate: self
        )
    }
}
