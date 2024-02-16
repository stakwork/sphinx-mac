//
//  NewMessageCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NewMessageCollectionViewItem: CommonNewMessageCollectionViewitem, ChatCollectionViewItemProtocol {
    
    @IBOutlet weak var messageContentStackView: NSStackView!
    
    @IBOutlet weak var bubbleAllViews: NSBox!
    @IBOutlet weak var receivedArrow: NSView!
    @IBOutlet weak var sentArrow: NSView!
    
    @IBOutlet weak var chatAvatarContainerView: NSView!
    @IBOutlet weak var chatAvatarView: ChatSmallAvatarView!
    @IBOutlet weak var sentMessageMargingView: NSView!
    @IBOutlet weak var receivedMessageMarginView: NSView!
    @IBOutlet weak var statusHeaderViewContainer: NSView!

    @IBOutlet weak var statusHeaderView: StatusHeaderView!
    
    ///First Container
    @IBOutlet weak var messageReplyView: NewMessageReplyView!
    
    ///Second Container
    @IBOutlet weak var invoicePaymentView: InvoicePaymentView!
    @IBOutlet weak var invoiceView: InvoiceView!
    @IBOutlet weak var sentPaidDetailsView: SentPaidDetails!
    @IBOutlet weak var paidTextMessageView: NSView!
    @IBOutlet weak var directPaymentView: DirectPaymentView!
    @IBOutlet weak var audioMessageView: AudioMessageView!
    @IBOutlet weak var podcastAudioView: PodcastAudioView!
    @IBOutlet weak var mediaMessageView: MediaMessageView!
    @IBOutlet weak var fileDetailsView: FileInfoView!
    @IBOutlet weak var callLinkView: JoinVideoCallView!
    @IBOutlet weak var podcastBoostView: PodcastBoostView!
    
    ///Thirs Container
    @IBOutlet weak var textMessageView: NSView!
    @IBOutlet weak var messageLabel: MessageTextField!
    @IBOutlet weak var messageLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!
    
    ///Forth Container
    @IBOutlet weak var botResponseView: BotResponseView!
    @IBOutlet weak var messageBoostView: NewMessageBoostView!
    @IBOutlet weak var linkPreviewView: NewLinkPreviewView!
    @IBOutlet weak var contactLinkPreviewView: ContactLinkView!
    @IBOutlet weak var tribeLinkPreviewView: TribeLinkView!
    @IBOutlet weak var paidAttachmentView: NewPaidAttachmentView!
    
    @IBOutlet weak var leftLineContainer: NSBox!
    @IBOutlet weak var rightLineContainer: NSBox!
    @IBOutlet weak var leftPaymentDot: NSBox!
    @IBOutlet weak var rightPaymentDot: NSBox!
    
    @IBOutlet weak var sentMessageMenuButton: CustomButton!
    @IBOutlet weak var receivedMessageMenuButton: CustomButton!
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var botResponseViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    func releaseMemory() {
        botResponseView.releaseMemory()
    }
    
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
        self.delegate = delegate
        
        ///Views Width
        configureViewsWidthWith(
            messageCellState: messageCellState,
            linkData: linkData,
            tribeData: tribeData,
            webViewData: botWebViewData
        )
        
        ///Status Header
        configureWith(statusHeader: mutableMessageCellState.statusHeader, uploadProgressData: uploadProgressData)
        
        ///Message content
        configureWith(
            messageCellState: mutableMessageCellState,
            searchingTerm: searchingTerm,
            linkData: linkData,
            tribeData: tribeData,
            collectionViewWidth: collectionViewWidth
        ) 
        
        ///Message Reply
        configureWith(messageReply: mutableMessageCellState.messageReply, and: bubble)

        ///Paid Content
        configureWith(paidContent: mutableMessageCellState.paidContent, and: bubble)
        
        ///Message types
        configureWith(payment: mutableMessageCellState.payment, and: bubble)
        configureWith(invoice: mutableMessageCellState.invoice, and: bubble)
        configureWith(directPayment: mutableMessageCellState.directPayment, and: bubble)
        configureWith(callLink: mutableMessageCellState.callLink)
        configureWith(podcastBoost: mutableMessageCellState.podcastBoost)
        configureWith(messageMedia: mutableMessageCellState.messageMedia, mediaData: mediaData, and: bubble)
        configureWith(genericFile: mutableMessageCellState.genericFile, mediaData: mediaData)
        configureWith(botHTMLContent: mutableMessageCellState.botHTMLContent, botWebViewData: botWebViewData)
        configureWith(audio: mutableMessageCellState.audio, mediaData: mediaData, and: bubble)
        configureWith(podcastComment: mutableMessageCellState.podcastComment, mediaData: mediaData, and: bubble)
        
        ///Bottom view
        configureWith(boosts: mutableMessageCellState.boosts, and: bubble)
        configureWith(contactLink: mutableMessageCellState.contactLink, and: bubble)
        configureWith(tribeLink: mutableMessageCellState.tribeLink, tribeData: tribeData, and: bubble)
//        configureWith(webLink: mutableMessageCellState.webLink, linkData: linkData)
        
        ///Avatar
        configureWith(avatarImage: mutableMessageCellState.avatarImage)
        
        ///Direction and grouping
        configureWith(bubble: bubble)
        
        ///Invoice Lines
        configureWith(invoiceLines: mutableMessageCellState.invoicesLines)
    }
    
    @IBAction func messageMenuButtonClicked(_ sender: Any) {
        if let button = sender as? NSButton, let messageId = messageId {
            delegate?.shouldShowOptionsFor(messageId: messageId, from: button)
        }
    }
}
