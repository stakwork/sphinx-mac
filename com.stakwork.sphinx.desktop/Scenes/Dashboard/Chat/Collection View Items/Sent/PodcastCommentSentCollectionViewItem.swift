//
//  PodcastCommentSentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class PodcastCommentSentCollectionViewItem: CommonPodcastCommentCollectionViewItem {

    @IBOutlet weak var seenSign: NSTextField!
    @IBOutlet weak var errorSign: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
        configureAudio(podcast: chat?.podcastPlayer?.podcast)
        configureMessageStatus()

        if messageRow.shouldShowRightLine {
           addRightLine()
        }

        if messageRow.shouldShowLeftLine {
           addLeftLine()
        }
        messageBubbleView.clearBubbleView()

        if messageRow.transactionMessage.hasMessageContent() {
            let (label, _) = messageBubbleView.showOutgoingMessageBubble(messageRow: messageRow, fixedBubbleWidth: CommonPodcastCommentCollectionViewItem.kAudioSentBubbleWidth)
            addLinksOnLabel(label: label)
        }
    }
    
    func configureAudio(podcast: PodcastFeed?) {
        guard let messageRow = messageRow else {
           return
        }

        let bubbleSize = CGSize(width: CommonPodcastCommentCollectionViewItem.kAudioSentBubbleWidth, height: CommonPodcastCommentCollectionViewItem.kAudioBubbleHeight)
        audioBubbleView.showOutgoingPodcastCommentBubble(messageRow: messageRow, size: bubbleSize)
        configureReplyBubble(bubbleView: audioBubbleView, bubbleSize: bubbleSize, incoming: false)

        tryLoadingAudio(messageRow: messageRow, podcast: podcast, bubbleSize: bubbleSize)
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
        
        seenSign.stringValue = received ? "flash_on" : ""
        seenSign.alphaValue = received ? 1.0 : 0.0
        errorSign.alphaValue = failed ? 1.0 : 0.0
    }
}
