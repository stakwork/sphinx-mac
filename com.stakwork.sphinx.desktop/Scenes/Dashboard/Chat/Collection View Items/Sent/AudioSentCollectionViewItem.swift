//
//  AudioSentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 26/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class AudioSentCollectionViewItem: CommonAudioCollectionViewItem, MediaUploadingProtocol {
    
    @IBOutlet weak var seenSign: NSTextField!
    @IBOutlet weak var errorSign: NSTextField!
    
    var uploading = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configureAudio()
        configureUploading()
        configureMessageStatus()

        if messageRow.shouldShowRightLine {
           addRightLine()
        }

        if messageRow.shouldShowLeftLine {
           addLeftLine()
        }
    }
    
    func configureAudio() {
        guard let messageRow = messageRow else {
           return
        }

        let bubbleSize = getBubbleSize()
        audioBubbleView.showOutgoingAudioBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: audioBubbleView, bubbleSize: bubbleSize, incoming: false)

        tryLoadingAudio(messageRow: messageRow, bubbleSize: bubbleSize)
    }

    func tryLoadingAudio(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        uploading = false

        if let url = messageRow.transactionMessage.getMediaUrl() {
            loadAudio(url: url, messageRow: messageRow, bubbleSize: bubbleSize)
        } else if !uploading {
            audioLoadingFailed()
        }
    }

    override func audioLoadingFailed() {
        super.audioLoadingFailed()
        configureMessageStatus()
    }

    override func toggleLoadingAudio(loading: Bool) {
        super.toggleLoadingAudio(loading: loading)
    }
    
    func configureMessageStatus() {
        guard let messageRow = messageRow else {
            return
        }
        
        configureLockSign()
        
        let received = messageRow.transactionMessage.received()
        let failed = messageRow.transactionMessage.failed()
        let expired = messageRow.transactionMessage.isMediaExpired()
        
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

        if let _ = messageRow.transactionMessage?.uploadingObject?.getUploadData() {
            uploading = true
            toggleLoadingAudio(loading: true)
            let progress = messageRow.transactionMessage?.uploadingProgress ?? 0

            seenSign.stringValue = ""
            lockSign.stringValue = ""

            let uploadedString = String(format: "uploaded.progress".localized, progress)
            dateLabel.stringValue = uploadedString
            dateLabel.font = NSFont(name: "Roboto-Medium", size: 10.0)!
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
