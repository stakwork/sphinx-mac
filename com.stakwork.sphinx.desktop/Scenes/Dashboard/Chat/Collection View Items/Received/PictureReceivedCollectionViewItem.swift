//
//  PictureReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PictureReceivedCollectionViewItem: CommonPictureCollectionViewItem {
    
    @IBOutlet weak var paidAttachmentView: PaidAttachmentView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configureStatus()
        configureImageAndMessage()
        configurePayment()

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configureImageAndMessage() {
        guard let messageRow = messageRow else {
            return
        }
        
        gifOverlayView.isHidden = true
        pdfInfoView.isHidden = true
        
        let bubbleHeight = messageRow.transactionMessage.isPDF() ? Constants.kPDFBubbleHeight : Constants.kPictureBubbleHeight
        let ratio = GiphyHelper.getAspectRatioFrom(message: messageRow.transactionMessage.messageContent ?? "")
        let bubbleSize = CGSize(width: Constants.kPictureBubbleHeight, height: bubbleHeight / CGFloat(ratio))
        bubbleView.showIncomingPictureBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: true)
        
        tryLoadingImage(messageRow: messageRow, bubbleSize: bubbleSize)
        
        messageBubbleView.clearBubbleView()

        if messageRow.transactionMessage.hasMessageContent() || messageRow.isBoosted {
            let (label, _) = messageBubbleView.showIncomingMessageBubble(messageRow: messageRow, fixedBubbleWidth: Constants.kPictureBubbleHeight)
            addLinksOnLabel(label: label)
        }
    }
    
    func configurePayment() {
        guard let messageRow = messageRow else {
            paidAttachmentView.isHidden = true
            return
        }
        
        paidAttachmentView.configure(messageRow: messageRow, delegate: self)
    }
    
    func configureStatus() {
//        guard let messageRow = messageRow else {
//            return
//        }
        
        configureLockSign()
        
//        let expired = messageRow.transactionMessage.isMediaExpired()
//        errorContainer.alpha = expired ? 1.0 : 0.0
    }
    
    func tryLoadingImage(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        if let nsUrl = messageRow.transactionMessage.getMediaUrl() {
            loadImage(url: nsUrl, messageRow: messageRow, bubbleSize: bubbleSize)
        } else if messageRow.transactionMessage.isGiphy() {
            loadGiphy(messageRow: messageRow, bubbleSize: bubbleSize)
        } else {
            imageLoadingFailed()
        }
    }
    
    override func loadImageInBubble(messageRow: TransactionMessageRow, size: CGSize, image: NSImage? = nil, gifData: Data? = nil) {
        super.loadImageInBubble(messageRow: messageRow, size: size)
        toggleLoadingImage(loading: false)
        pictureImageView.image = nil
        bubbleView.showIncomingPictureBubble(messageRow: messageRow, size: size, image: image, gifData: gifData)
    }
}

extension PictureReceivedCollectionViewItem : PaidAttachmentViewDelegate {
    func didTapPayButton() {
        if let message = messageRow?.transactionMessage {
            let price = message.getAttachmentPrice() ?? 0
            paidAttachmentView.configure(status: TransactionMessage.TransactionMessageType.purchase, price: price)
            delegate?.didTapPayAttachment(transactionMessage: message)
        }
    }
}
