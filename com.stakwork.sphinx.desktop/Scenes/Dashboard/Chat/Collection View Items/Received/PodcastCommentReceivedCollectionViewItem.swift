//
//  PodcastCommentReceivedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PodcastCommentReceivedCollectionViewItem: CommonPodcastCommentCollectionViewItem {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configureStatus()
        
        let bubbleSize = CGSize(width: CommonPodcastCommentCollectionViewItem.kAudioReceivedBubbleWidth, height: CommonPodcastCommentCollectionViewItem.kAudioBubbleHeight)
        audioBubbleView.showIncomingPodcastCommentBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: audioBubbleView, bubbleSize: bubbleSize, incoming: true)

        tryLoadingAudio(messageRow: messageRow, podcast: chat?.podcastPlayer?.podcast, bubbleSize: bubbleSize)

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
        messageBubbleView.clearBubbleView()

        if messageRow.transactionMessage.hasMessageContent() {
            let (label, _) = messageBubbleView.showIncomingMessageBubble(messageRow: messageRow, fixedBubbleWidth: CommonPodcastCommentCollectionViewItem.kAudioReceivedBubbleWidth)
            label.addLinksOnLabel()
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
    
    func tryLoadingAudio(messageRow: TransactionMessageRow, podcast: PodcastFeed?, bubbleSize: CGSize) {
        if let podcastComment = messageRow.transactionMessage.podcastComment, let _ = podcastComment.url {
            loadAudio(podcastComment: podcastComment, podcast: podcast, messageRow: messageRow, bubbleSize: bubbleSize)
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
