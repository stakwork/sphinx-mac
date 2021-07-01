//
//  VideoSentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 29/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class VideoSentCollectionViewItem: CommonVideoCollectionViewItem, MediaUploadingProtocol {
    
    @IBOutlet weak var seenSign: NSTextField!
    @IBOutlet weak var attachmentPriceView: AttachmentPriceView!
    @IBOutlet weak var uploadCancelButton: NSButton!
    @IBOutlet weak var errorSign: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    var uploading = false

    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configureImageAndVideo()
        configureUploading()
        configureMessageStatus()
        configurePrice(messageRow: messageRow)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configurePrice(messageRow: TransactionMessageRow) {
        let price = messageRow.transactionMessage.getAttachmentPrice() ?? 0
        let statusAttributes = messageRow.transactionMessage.getPurchaseStatusLabel(queryDB: false)
        attachmentPriceView.configure(price: price, status: statusAttributes)
    }

    func configureImageAndVideo() {
        guard let messageRow = messageRow else {
            return
        }

        let bubbleSize = CGSize(width: Constants.kPictureBubbleHeight, height: Constants.kPictureBubbleHeight)
        bubbleView.showOutgoingPictureBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: false)

        tryLoadingVideo(messageRow: messageRow, bubbleSize: bubbleSize)
        messageBubbleView.clearBubbleView()

        if messageRow.transactionMessage.hasMessageContent() || messageRow.isBoosted {
           let (label, _) = messageBubbleView.showOutgoingMessageBubble(messageRow: messageRow, fixedBubbleWidth: Constants.kPictureBubbleHeight)
           addLinksOnLabel(label: label)
        }
    }

    func tryLoadingVideo(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        uploading = false

        if let url = messageRow.transactionMessage.getMediaUrl() {
            loadVideo(url: url, messageRow: messageRow, bubbleSize: bubbleSize)
        } else if !uploading {
            videoLoadingFailed()
        }
    }

    override func videoLoadingFailed() {
        super.videoLoadingFailed()
    }

    override func toggleLoadingImage(loading: Bool) {
        super.toggleLoadingImage(loading: loading)
    }

    override func loadImageInBubble(messageRow: TransactionMessageRow, size: CGSize, image: NSImage) {
        toggleLoadingImage(loading: false)
        bubbleView.showOutgoingPictureBubble(messageRow: messageRow, size: size, image: image)
    }
    
    func configureMessageStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        let received = messageRow.transactionMessage.received()
        let failed = messageRow.transactionMessage.failed()
        let expired = messageRow.transactionMessage.isMediaExpired()
        configureLockSign()
        
        seenSign.stringValue = received ? "flash_on" : ""
        seenSign.alphaValue = received ? 1.0 : 0.0
        errorSign.alphaValue = failed || expired ? 1.0 : 0.0
    }

    func configureUploading() {
        guard let messageRow = messageRow, messageRow.transactionMessage.getMediaUrl() == nil else {
            return
        }

        if messageRow.transactionMessage?.isCancelled() ?? false {
            return
        }

        if let image = messageRow.transactionMessage?.uploadingObject?.image {
            uploading = true
            let progress = messageRow.transactionMessage?.uploadingProgress ?? 0

            let bubbleSize = CGSize(width: Constants.kPictureBubbleHeight, height: Constants.kPictureBubbleHeight)
            bubbleView.showOutgoingPictureBubble(messageRow: messageRow, size: bubbleSize, image: image)

            seenSign.stringValue = ""
            lockSign.stringValue = ""

            let uploadedString = String(format: "uploaded.progress".localized, progress)
            dateLabel.stringValue = uploadedString
            dateLabel.font = NSFont(name: "Roboto-Medium", size: 10.0)!

            uploadCancelButton.isHidden = false
            toggleLoadingImage(loading: true)

            for subview in messageBubbleView.getSubviews() {
               if subview.tag == MessageBubbleView.kMessageLabelTag {
                   subview.alphaValue = 0.5
               }
            }
        }
    }

    func isUploading() -> Bool {
        return uploading && self.messageRow?.transactionMessage.uploadingObject?.image != nil
    }

    func configureUploadingProgress(progress: Int, finishUpload: Bool) {
        messageRow?.transactionMessage?.uploadingProgress = progress
        let uploadedString = String(format: "uploaded.progress".localized, progress)
        dateLabel.stringValue = uploadedString
        uploadCancelButton.isHidden = finishUpload
    }
    
    @IBAction func playButtonClicked(_ sender: Any) {
        if let message = messageRow?.transactionMessage {
            delegate?.didTapAttachmentRow(message: message)
        }
    }
    
    @IBAction func cancelUploadButtonClicked(_ sender: Any) {
        if let message = messageRow?.transactionMessage {
            delegate?.didTapAttachmentCancel?(transactionMessage: message)
        }
    }
}
