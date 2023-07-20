//
//  NewMessageReplyView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol NewMessageReplyViewDelegate: AnyObject {
    func didTapMessageReplyView()
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
        
    }
    
    func configureWith(
        messageReply: BubbleMessageLayoutState.MessageReply,
        and bubble: BubbleMessageLayoutState.Bubble,
        delegate: NewMessageReplyViewDelegate? = nil
    ) {
        self.delegate = delegate
        
        messageLabel.textColor = bubble.direction.isIncoming() ? NSColor.Sphinx.WashedOutReceivedText : NSColor.Sphinx.WashedOutSentText
        
        coloredLineView.fillColor = messageReply.color
        senderLabel.textColor = messageReply.color
        senderLabel.stringValue = messageReply.alias
        messageLabel.stringValue = messageReply.message ?? ""
        
        guard let mediaType = messageReply.mediaType else {
            mediaContainerView.isHidden = true
            imageVideoView.isHidden = true
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
    
    @IBAction func replyButtonClicked(_ sender: Any) {
        delegate?.didTapMessageReplyView()
    }
}
