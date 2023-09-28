//
//  ThreadCollectionView+DelegatesExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 27/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension ThreadCollectionViewItem : ChatSmallAvatarViewDelegate {
    func didClickAvatarView() {
        if let messageId = messageId {
            delegate?.didTapAvatarViewFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension ThreadCollectionViewItem : NewMessageReplyViewDelegate {
    func didTapMessageReplyView() {
        if let messageId = messageId {
            delegate?.didTapMessageReplyFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension ThreadCollectionViewItem : LinkPreviewDelegate {
    func didTapOnTribeButton() {
        if let messageId = messageId {
            delegate?.didTapTribeButtonFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapOnContactButton() {
        if let messageId = messageId {
            delegate?.didTapContactButtonFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapOnWebLinkButton() {
        if let messageId = messageId {
            delegate?.didTapOnLinkButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension ThreadCollectionViewItem : MediaMessageViewDelegate {
    func didTapMediaButton() {
        if let messageId = messageId {
            delegate?.didTapMediaButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension ThreadCollectionViewItem : JoinCallViewDelegate {
    func didTapCopyLink() {
        if let messageId = messageId {
            delegate?.didTapCallLinkCopyFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapAudioButton() {
        if let messageId = messageId {
            delegate?.didTapCallJoinAudioFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func didTapVideoButton() {
        if let messageId = messageId {
            delegate?.didTapCallJoinVideoFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension ThreadCollectionViewItem : FileInfoViewDelegate {
    func didTouchDownloadButton() {
        if let messageId = messageId, let message = TransactionMessage.getMessageWith(id: messageId) {
            MediaDownloader.shouldSaveFile(message: message, completion: { (success, alertMessage) in
                DispatchQueue.main.async {
                    NewMessageBubbleHelper().showGenericMessageView(text: alertMessage)
                }
            })
        }
    }
}

extension ThreadCollectionViewItem : AudioMessageViewDelegate {
    func didTapPlayPauseButton() {
        if let messageId = messageId {
            delegate?.didTapPlayPauseButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension ThreadCollectionViewItem : PodcastAudioViewDelegate {
    func didTapClipPlayPauseButtonAt(time: Double) {
        if let messageId = messageId {
            delegate?.didTapClipPlayPauseButtonFor(messageId: messageId, and: rowIndex, atTime: time)
        }
    }
    
    func shouldSeekTo(time: Double) {
        if let messageId = messageId {
            delegate?.shouldSeekClipFor(messageId: messageId, and: rowIndex, atTime: time)
        }
    }
}

extension ThreadCollectionViewItem : PaidAttachmentViewDelegate {
    func didTapPayButton() {
        if let messageId = messageId {
            delegate?.didTapPayButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension ThreadCollectionViewItem : InvoiceViewDelegate {
    func didTapInvoicePayButton() {
        if let messageId = messageId {
            delegate?.didTapInvoicePayButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}
