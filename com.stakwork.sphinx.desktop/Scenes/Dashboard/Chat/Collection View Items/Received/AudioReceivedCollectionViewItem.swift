//
//  AudioReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 26/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class AudioReceivedCollectionViewItem: CommonAudioCollectionViewItem {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configureStatus()
        
        let bubbleSize = getBubbleSize()
        audioBubbleView.showIncomingAudioBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: audioBubbleView, bubbleSize: bubbleSize, incoming: true)

        tryLoadingAudio(messageRow: messageRow, bubbleSize: bubbleSize)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    func configureStatus() {
//        guard let messageRow = messageRow else {
//            return
//        }
        
        configureLockSign()
//
//        let expired = messageRow.transactionMessage.isMediaExpired()
//        errorContainer.alpha = expired ? 1.0 : 0.0
    }
    
    func tryLoadingAudio(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        if let url = messageRow.transactionMessage.getMediaUrl() {
            loadAudio(url: url, messageRow: messageRow, bubbleSize: bubbleSize)
        } else {
            audioLoadingFailed()
        }
    }
    
    override func audioLoadingFailed() {
        super.audioLoadingFailed()
    }
    
    override func toggleLoadingAudio(loading: Bool) {
        super.toggleLoadingAudio(loading: loading)
    }
}
