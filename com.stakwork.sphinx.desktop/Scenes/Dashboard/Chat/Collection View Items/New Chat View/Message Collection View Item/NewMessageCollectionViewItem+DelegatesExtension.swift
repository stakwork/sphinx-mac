//
//  NewMessageCollectionViewItem+DelegatesExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension NewMessageCollectionViewItem : NewMessageReplyViewDelegate {
    func didTapMessageReplyView() {
        if let messageId = messageId {
            delegate?.didTapMessageReplyFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension NewMessageCollectionViewItem : LinkPreviewDelegate {
    func didTapOnTribeButton() {
//        if let messageId = messageId {
//            delegate?.didTapTribeButtonFor(messageId: messageId, and: rowIndex)
//        }
    }
    
    func didTapOnContactButton() {
//        if let messageId = messageId {
//            delegate?.didTapContactButtonFor(messageId: messageId, and: rowIndex)
//        }
    }
    
    func didTapOnWebLinkButton() {
        if let messageId = messageId {
            delegate?.didTapOnLinkButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}
