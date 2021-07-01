//
//  VideoReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 29/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class VideoReceivedCollectionViewItem: CommonVideoCollectionViewItem {
    
    @IBOutlet weak var paidAttachmentView: PaidAttachmentView!
    //    @IBOutlet weak var errorContainer: UIView!
//    @IBOutlet weak var paidAttachmentView: PaidAttachmentView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configureStatus()
        
        let bubbleSize = CGSize(width: Constants.kPictureBubbleHeight, height: Constants.kPictureBubbleHeight)
        bubbleView.showIncomingPictureBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: true)
        
        tryLoadingVideo(messageRow: messageRow, bubbleSize: bubbleSize)
        
        messageBubbleView.clearBubbleView()

        if messageRow.transactionMessage.hasMessageContent() || messageRow.isBoosted {
            let (label, _) = messageBubbleView.showIncomingMessageBubble(messageRow: messageRow, fixedBubbleWidth: Constants.kPictureBubbleHeight)
            addLinksOnLabel(label: label)
        }
        
        configurePayment()

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
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
    
    func tryLoadingVideo(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        if let url = messageRow.transactionMessage.getMediaUrl() {
            loadVideo(url: url, messageRow: messageRow, bubbleSize: bubbleSize)
        } else {
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
        bubbleView.showIncomingPictureBubble(messageRow: messageRow, size: size, image: image)
    }
    
    @IBAction func playButtonClicked(_ sender: Any) {
        if let message = messageRow?.transactionMessage {
            delegate?.didTapAttachmentRow(message: message)
        }
    }
}

extension VideoReceivedCollectionViewItem : PaidAttachmentViewDelegate {
    func didTapPayButton() {
        if let message = messageRow?.transactionMessage {
            let price = message.getAttachmentPrice() ?? 0
            paidAttachmentView.configure(status: TransactionMessage.TransactionMessageType.purchase, price: price)
            delegate?.didTapPayAttachment(transactionMessage: message)
        }
    }
}
