//
//  FileSentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class FileSentCollectionViewItem: CommonFileCollectionViewItem, MediaUploadingProtocol {
    
    @IBOutlet weak var seenSign: NSTextField!
    @IBOutlet weak var attachmentPriceView: AttachmentPriceView!
    @IBOutlet weak var bubbleViewHeight: NSLayoutConstraint!
    
    var uploading = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        
        commonConfigurationForMessages()
        setBubbleViewHeight()
        configureFile()
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
    
    override func getBubbbleView() -> NSView? {
        return messageBubbleView
    }
    
    func setBubbleViewHeight() {
        bubbleViewHeight.constant = messageRow!.isPaidSentAttachment ? Constants.kPaidFileBubbleHeight : Constants.kFileBubbleHeight
        bubbleView.layoutSubtreeIfNeeded()
    }
    
    func configurePrice(messageRow: TransactionMessageRow) {
        let price = messageRow.transactionMessage.getAttachmentPrice() ?? 0
        let statusAttributes = messageRow.transactionMessage.getPurchaseStatusLabel(queryDB: false)
        attachmentPriceView.configure(price: price, status: statusAttributes)
    }
    
    func configureFile() {
        guard let messageRow = messageRow else {
            return
        }
        
        let bubbleHeight = messageRow.isPaidSentAttachment ? Constants.kPaidFileBubbleHeight : Constants.kFileBubbleHeight
        let bottomBubblePadding = messageRow.isBoosted ? Constants.kReactionsViewHeight : 0
        let bubbleSize = CGSize(width: Constants.kFileBubbleWidth, height: bubbleHeight + bottomBubblePadding)
        bubbleView.showOutgoingFileBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: bubbleView, bubbleSize: bubbleSize, incoming: false)
        
        tryLoadingData(messageRow: messageRow, bubbleSize: bubbleSize)
        messageBubbleView.clearBubbleView()

        if messageRow.transactionMessage.hasMessageContent() {
            let (label, _) = messageBubbleView.showOutgoingMessageBubble(messageRow: messageRow, fixedBubbleWidth: Constants.kFileBubbleWidth)
            addLinksOnLabel(label: label)
        }
    }
    
    func tryLoadingData(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        uploading = false
        
        if let nsUrl = messageRow.transactionMessage.getMediaUrl() {
            loadFile(url: nsUrl, messageRow: messageRow, bubbleSize: bubbleSize)
        } else {
            fileLoadingFailed()
        }
    }
    
    func configureMessageStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        let received = messageRow.transactionMessage.received()
        configureLockSign()
        
        seenSign.stringValue = received ? "flash_on" : ""
        seenSign.alphaValue = received ? 1.0 : 0.0
    }
    
    func configureUploading() {
        guard let messageRow = messageRow, messageRow.transactionMessage.getMediaUrl() == nil else {
            return
        }
        
        if messageRow.transactionMessage?.isCancelled() ?? false {
            return
        }
        
        if let data = messageRow.transactionMessage?.uploadingObject?.getUploadData() {
            uploading = true
            
            let progress = messageRow.transactionMessage?.uploadingProgress ?? 0
            
            seenSign.stringValue = ""
            lockSign.stringValue = ""
            
            let uploadedString = String(format: "uploaded.progress".localized, progress)
            dateLabel.stringValue = uploadedString
            dateLabel.font = NSFont(name: "Roboto-Medium", size: 10.0)!
            
            let decryptedData = messageRow.transactionMessage?.uploadingObject?.getDecryptedData()
            fileNameLabel.stringValue = messageRow.transactionMessage?.mediaFileName ?? "file".localized
            fileSizeLabel.stringValue = decryptedData?.formattedSize ?? data.formattedSize
            
            toggleLoadingImage(loading: true)
            
            for subview in messageBubbleView.getSubviews() {
                if subview.tag == MessageBubbleView.kMessageLabelTag {
                    subview.alphaValue = 0.5
                }
            }
        }
    }
    
    func isUploading() -> Bool {
        return uploading && self.messageRow?.transactionMessage.uploadingObject?.getUploadData() != nil
    }
    
    func configureUploadingProgress(progress: Int, finishUpload: Bool) {
        messageRow?.transactionMessage?.uploadingProgress = progress
        let uploadedString = String(format: "uploaded.progress".localized, progress)
        dateLabel.stringValue = uploadedString
    }
}
