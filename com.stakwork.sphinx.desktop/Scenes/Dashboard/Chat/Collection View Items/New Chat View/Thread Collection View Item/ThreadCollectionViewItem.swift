//
//  ThreadCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 27/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ThreadCollectionViewItemContentView: NSView {
    @IBOutlet weak var messageView: NSView!
    @IBOutlet weak var repliesView: ThreadRepliesView!
    @IBOutlet weak var lastMessageHeaderView: ThreadLastMessageHeader!
    @IBOutlet weak var lastReplyTextMessageView: NSView!
        
    override func mouseDown(with event: NSEvent) {
        guard let superview = messageView.superview else { return }
        
        let pointInView = superview.convert(event.locationInWindow, from: nil)
        
        if messageView.hitTest(pointInView) != nil ||
            repliesView.hitTest(pointInView) != nil ||
            lastMessageHeaderView.hitTest(pointInView) != nil ||
            lastReplyTextMessageView.hitTest(pointInView) != nil
        {
            super.mouseDown(with: event)
        }
    }
}

class ThreadCollectionViewItem: CommonNewMessageCollectionViewitem, ChatCollectionViewItemProtocol {
    
    @IBOutlet weak var messageContentStackView: NSStackView!
    
    @IBOutlet weak var bubbleAllViews: NSBox!
    @IBOutlet weak var bubbleLastReplyView: NSBox!
    @IBOutlet weak var textMessageBubbleView: NSBox!
    
    @IBOutlet weak var receivedArrow: NSView!
    @IBOutlet weak var sentArrow: NSView!
    
    @IBOutlet weak var chatAvatarContainerView: NSView!
    @IBOutlet weak var chatAvatarView: ChatSmallAvatarView!
    @IBOutlet weak var sentMessageMargingView: NSView!
    @IBOutlet weak var receivedMessageMarginView: NSView!
    
    @IBOutlet weak var statusHeaderViewContainer: NSView!
    @IBOutlet weak var statusHeaderView: StatusHeaderView!
    
    ///Second Container
    @IBOutlet weak var audioMessageView: AudioMessageView!
    @IBOutlet weak var mediaMessageContainer: NSView!
    @IBOutlet weak var mediaMessageView: MediaMessageView!
    @IBOutlet weak var fileDetailsView: FileInfoView!
    
    ///Thirs Container
    @IBOutlet weak var textMessageView: NSView!
    @IBOutlet weak var messageLabel: MessageTextField!
    @IBOutlet weak var messageLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!
    
    ///Thread
    @IBOutlet weak var threadRepliesView: ThreadRepliesView!
    @IBOutlet weak var threadLastMessageHeader: ThreadLastMessageHeader!
    
    ///Forth Container
    @IBOutlet weak var lastReplyAudioMessageView: AudioMessageView!
    @IBOutlet weak var lastReplyMediaMessageView: MediaMessageView!
    @IBOutlet weak var lastReplyFileDetailsView: FileInfoView!
    @IBOutlet weak var lastReplyTextMessageView: NSView!
    @IBOutlet weak var lastReplyMessageLabel: MessageTextField!
    @IBOutlet weak var lastReplyMessageLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var lastReplyMessageLabelTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var leftLineContainer: NSBox!
    @IBOutlet weak var rightLineContainer: NSBox!
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var lastReplyLabelHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    func releaseMemory() {}
    
    func configureWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        threadOriginalMsgMediaData: MessageTableCellState.MediaData?,
        tribeData: MessageTableCellState.TribeData?,
        linkData: MessageTableCellState.LinkData?,
        botWebViewData: MessageTableCellState.BotWebViewData?,
        uploadProgressData: MessageTableCellState.UploadProgressData?,
        delegate: ChatCollectionViewItemDelegate?,
        searchingTerm: String?,
        indexPath: IndexPath,
        collectionViewWidth: CGFloat
    ) {
        hideAllSubviews()
        
        var mutableMessageCellState = messageCellState
        
        guard let bubble = mutableMessageCellState.bubble else {
            return
        }
        
        self.rowIndex = indexPath.item
        self.messageId = mutableMessageCellState.message?.id
        self.originalMessageId = mutableMessageCellState.threadOriginalMessage?.id
        self.delegate = delegate
        
        ///Views Width
        configureWidth()
        
        ///Status Header
        configureWith(statusHeader: mutableMessageCellState.statusHeader, uploadProgressData: uploadProgressData)
        
        ///Avatar
        configureWith(avatarImage: mutableMessageCellState.avatarImage)
        
        ///Original Message
        configureOriginalMessageTextWith(
            threadMessage: mutableMessageCellState.threadMessagesState,
            searchingTerm: searchingTerm,
            collectionViewWidth: collectionViewWidth
        )
        configureWith(
            originalMessageMedia: mutableMessageCellState.threadOriginalMessageMedia,
            mediaData: threadOriginalMsgMediaData,
            and: bubble
        )
        configureWith(
            originalMessageAudio: mutableMessageCellState.threadOriginalMessageAudio,
            mediaData: threadOriginalMsgMediaData,
            and: bubble
        )
        configureWith(
            originalMessaggeGenericFile: mutableMessageCellState.threadOriginalMessageGenericFile,
            mediaData: threadOriginalMsgMediaData
        )
        
        
        ///Last Reply
        configureLastReplyWith(
            messageContent: mutableMessageCellState.messageContent,
            searchingTerm: searchingTerm,
            collectionViewWidth: collectionViewWidth
        )
        configureLastReplyWith(
            messageMedia: mutableMessageCellState.messageMedia,
            mediaData: mediaData,
            and: bubble
        )
        configureLastReplyWith(
            audio: mutableMessageCellState.audio,
            mediaData: mediaData,
            and: bubble
        )
        configureLastReplyWith(
            genericFile: mutableMessageCellState.genericFile,
            mediaData: mediaData
        )
        
        ///Thread
        configureWith(threadMessages: mutableMessageCellState.threadMessagesState, and: bubble)
        configureWith(threadLastReply: mutableMessageCellState.threadLastReplyHeader, and: bubble)
        
        ///Direction and grouping
        configureWith(bubble: bubble, threadMessages: mutableMessageCellState.threadMessagesState)
        
        ///Invoice Lines
        configureWith(invoiceLines: mutableMessageCellState.invoicesLines)
    }
}
