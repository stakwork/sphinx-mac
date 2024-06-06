//
//  NewReplyView.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 05/06/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

class KeyboardReplyView: NSView, LoadableNib {
    
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
    
    @IBOutlet weak var closeButtonContainer: NSBox!
    @IBOutlet weak var closeButton: CustomButton!
    
    @IBOutlet weak var viewButton: CustomButton!
    @IBOutlet weak var replyToLabel: NSTextField!
    
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
    
    func configureForKeyboard(
        with podcastComment: PodcastComment,
        and delegate: NewMessageReplyViewDelegate
    ) {
        self.delegate = delegate
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.Sphinx.HeaderBG.cgColor
        
        replyToLabel.isHidden = true
        
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
        
        replyToLabel.isHidden = false
        
        viewButton.isHidden = true
        closeButtonContainer.isHidden = false
        
        messageLabel.textColor = NSColor.Sphinx.SecondaryText
        
        let senderColor = ChatHelper.getSenderColorFor(message: message)
        coloredLineView.fillColor = senderColor
        senderLabel.textColor = senderColor
        senderLabel.stringValue = message.getMessageSenderNickname(
            owner: owner,
            contact: nil
        ).trim()
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
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        delegate?.didCloseReplyView?()
    }
    
}
