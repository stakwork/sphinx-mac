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

extension NewMessageCollectionViewItem : MediaMessageViewDelegate {
    func didTapMediaButton() {
        if let messageId = messageId {
            delegate?.didTapMediaButtonFor(messageId: messageId, and: rowIndex)
        }
    }
    
    func shouldLoadOriginalMessageMediaDataFrom(
        originalMessageMedia: BubbleMessageLayoutState.MessageMedia
    ) {
//        if let originalMessageId = originalMessageId {
//            let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
//            DispatchQueue.global().asyncAfter(deadline: delayTime) {
//                if originalMessageMedia.isImage {
//                    self.delegate?.shouldLoadImageDataFor(
//                        messageId: originalMessageId,
//                        and: self.rowIndex
//                    )
//                } else if originalMessageMedia.isPdf {
//                    self.delegate?.shouldLoadPdfDataFor(
//                        messageId: originalMessageId,
//                        and: self.rowIndex
//                    )
//                } else if originalMessageMedia.isVideo {
//                    self.delegate?.shouldLoadVideoDataFor(
//                        messageId: originalMessageId,
//                        and: self.rowIndex
//                    )
//                } else if originalMessageMedia.isGiphy {
//                    self.delegate?.shouldLoadGiphyDataFor(
//                        messageId: originalMessageId,
//                        and: self.rowIndex
//                    )
//                }
//            }
//        }
    }
    
    func shouldLoadOriginalMessageFileDataFrom(
        originalMessageFile: BubbleMessageLayoutState.GenericFile
    ) {
//        if let originalMessageId = originalMessageId {
//            let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
//            DispatchQueue.global().asyncAfter(deadline: delayTime) {
//                self.delegate?.shouldLoadFileDataFor(
//                    messageId: originalMessageId,
//                    and: self.rowIndex
//                )
//            }
//        }
    }
}
