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

extension NewMessageCollectionViewItem : JoinCallViewDelegate {
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

extension NewMessageCollectionViewItem : FileInfoViewDelegate {
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

extension NewMessageCollectionViewItem : AudioMessageViewDelegate {
    func didTapPlayPauseButton() {
        if let messageId = messageId {
            delegate?.didTapPlayPauseButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension NewMessageCollectionViewItem : PodcastAudioViewDelegate {
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

extension NewMessageCollectionViewItem : PaidAttachmentViewDelegate {
    func didTapPayButton() {
        if let messageId = messageId {
            delegate?.didTapPayButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}

extension NewMessageCollectionViewItem : InvoiceViewDelegate {
    func didTapInvoicePayButton() {
        if let messageId = messageId {
            delegate?.didTapInvoicePayButtonFor(messageId: messageId, and: rowIndex)
        }
    }
}
