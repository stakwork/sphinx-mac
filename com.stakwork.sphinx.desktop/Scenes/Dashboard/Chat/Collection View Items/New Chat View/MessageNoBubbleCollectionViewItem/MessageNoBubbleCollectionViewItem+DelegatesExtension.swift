//
//  MessageNoBubbleCollectionViewItem+DelegatesExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension MessageNoBubbleCollectionViewItem : GroupActionsViewDelegate {
    func didTapDeleteTribeButton() {
        if let messageId = messageId {
            delegate?.didTapDeleteTribeButtonFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapApproveRequestButton() {
        if let messageId = messageId {
            delegate?.didTapApproveRequestButtonFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapRejectRequestButton() {
        if let messageId = messageId {
            delegate?.didTapRejectRequestButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}
