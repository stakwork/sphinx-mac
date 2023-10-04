//
//  NewMessageReplyView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

@objc protocol NewMessageReplyViewDelegate: AnyObject {
    @objc optional func didTapMessageReplyView()
    @objc optional func didCloseReplyView()
}

class NewMessageReplyView: NSView, LoadableNib {
    
    weak var delegate: NewMessageReplyViewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var coloredLineView: NSBox!
    
    @IBOutlet weak var mediaContainerView: NSStackView!
    
    @IBOutlet weak var imageVideoView: NSView!
    @IBOutlet weak var mediaImageView: AspectFillNSImageView!
    @IBOutlet weak var videoOverlay: NSBox!
    
    @IBOutlet weak var mediaIconLabel: NSTextField!
    
    @IBOutlet weak var senderLabel: NSTextField!
    @IBOutlet weak var messageLabel: NSTextField!
    
    @IBOutlet weak var replyDivider: NSView!
    
    @IBOutlet weak var closeButtonContainer: NSBox!
    @IBOutlet weak var closeButton: CustomButton!
    
    @IBOutlet weak var viewButton: CustomButton!
    
    static let kViewHeight: CGFloat = 50.0

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setup()
    }
    
    func setup() {
        closeButton.cursor = .pointingHand
        viewButton.cursor = .pointingHand
    }
    
    func configureWith(
        messageReply: BubbleMessageLayoutState.MessageReply,
        and bubble: BubbleMessageLayoutState.Bubble,
        delegate: NewMessageReplyViewDelegate? = nil
    ) {
        self.delegate = delegate
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
        
        viewButton.isHidden = false
        closeButtonContainer.isHidden = true
        
        messageLabel.textColor = bubble.direction.isIncoming() ? NSColor.Sphinx.WashedOutReceivedText : NSColor.Sphinx.WashedOutSentText
        
        coloredLineView.fillColor = messageReply.color
        senderLabel.textColor = messageReply.color
        senderLabel.stringValue = messageReply.alias
        messageLabel.stringValue = messageReply.message ?? ""
        
        messageLabel.isHidden = (messageReply.message ?? "").isEmpty
        
        guard let mediaType = messageReply.mediaType else {
            mediaContainerView.isHidden = true
            mediaIconLabel.isHidden = true
            return
        }
        
        switch(mediaType) {
        case TransactionMessage.TransactionMessageType.imageAttachment.rawValue:
            mediaIconLabel.stringValue = "photo_library"
            break
        case TransactionMessage.TransactionMessageType.videoAttachment.rawValue:
            mediaIconLabel.stringValue = "videocam"
            break
        case TransactionMessage.TransactionMessageType.audioAttachment.rawValue:
            mediaIconLabel.stringValue = "mic"
            break
        case TransactionMessage.TransactionMessageType.fileAttachment.rawValue:
            mediaIconLabel.stringValue = "description"
            break
        case TransactionMessage.TransactionMessageType.pdfAttachment.rawValue:
            mediaIconLabel.stringValue = "picture_as_pdf"
            break
        default:
            break
        }
        
        mediaContainerView.isHidden = false
        mediaIconLabel.isHidden = false
    }
    
    func configureForKeyboard(
        with podcastComment: PodcastComment,
        and delegate: NewMessageReplyViewDelegate
    ) {
        self.delegate = delegate
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.Sphinx.HeaderBG.cgColor
        
        viewButton.isHidden = true
        closeButtonContainer.isHidden = false
        
        coloredLineView.fillColor = NSColor.Sphinx.SecondaryText
        
        let (hours, minutes, seconds) = (podcastComment.timestamp ?? 0).getTimeElements()
        let title = podcastComment.title ?? "title.not.available".localized
        let message = "Share audio clip: \(hours):\(minutes):\(seconds)"
        senderLabel.textColor = NSColor.Sphinx.Text
        senderLabel.stringValue = title
        
        messageLabel.textColor = NSColor.Sphinx.SecondaryText
        messageLabel.stringValue = message
        messageLabel.isHidden = message.isEmpty
        
        mediaContainerView.isHidden = true
        mediaIconLabel.isHidden = true

        self.isHidden = false
    }
    
    func configureForKeyboard(
        with message: TransactionMessage,
        owner: UserContact,
        and delegate: NewMessageReplyViewDelegate
    ) {
        self.delegate = delegate
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.Sphinx.HeaderBG.cgColor
        
        viewButton.isHidden = true
        closeButtonContainer.isHidden = false
        
        messageLabel.textColor = NSColor.Sphinx.SecondaryText
        
        let senderColor = ChatHelper.getSenderColorFor(message: message)
        coloredLineView.fillColor = senderColor
        senderLabel.textColor = senderColor
        senderLabel.stringValue = message.getMessageSenderNickname(
            owner: owner,
            contact: nil
        )
        messageLabel.stringValue = message.getReplyMessageContent()
        messageLabel.isHidden = message.getReplyMessageContent().isEmpty
        
        if message.isMediaAttachment() {
            
            if message.isAudio() {
                mediaIconLabel.stringValue = "mic"
            } else if message.isVideo() {
                mediaIconLabel.stringValue = "videocam"
            } else if message.isGiphy() || message.isPicture() {
                mediaIconLabel.stringValue = "photo_library"
            } else if message.isPDF() {
                mediaIconLabel.stringValue = "picture_as_pdf"
            } else {
                mediaIconLabel.stringValue = "description"
            }
            
            mediaContainerView.isHidden = false
            mediaIconLabel.isHidden = false
        } else {
            mediaContainerView.isHidden = true
            mediaIconLabel.isHidden = true
        }
        
        self.isHidden = false
    }
    
    func resetAndHide() {
        self.isHidden = true
    }
    
    @IBAction func replyButtonClicked(_ sender: Any) {
        delegate?.didTapMessageReplyView?()
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        delegate?.didCloseReplyView?()
    }
    
}
