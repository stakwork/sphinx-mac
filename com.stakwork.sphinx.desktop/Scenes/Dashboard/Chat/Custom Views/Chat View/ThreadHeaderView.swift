//
//  ThreadHeaderView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

@objc protocol ThreadHeaderViewDelegate {
    @objc optional func shouldLoadImageDataFor(messageId: Int, and rowIndex: Int)
    @objc optional func shouldLoadPdfDataFor(messageId: Int, and rowIndex: Int)
    @objc optional func shouldLoadFileDataFor(messageId: Int, and rowIndex: Int)
    @objc optional func shouldLoadVideoDataFor(messageId: Int, and rowIndex: Int)
    @objc optional func shouldLoadGiphyDataFor(messageId: Int, and rowIndex: Int)
    @objc optional func shouldLoadAudioDataFor(messageId: Int, and rowIndex: Int)
    
    func didTapMediaButtonFor(messageId: Int, and rowIndex: Int)
    func didTapFileDownloadButtonFor(messageId: Int, and rowIndex: Int)
    func didTapPlayPauseButtonFor(messageId: Int, and rowIndex: Int)
}

class ThreadHeaderView: NSView, LoadableNib {
    
    var delegate : ThreadHeaderViewDelegate? = nil
    
    var messageId: Int?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var chatAvatarView: ChatSmallAvatarView!
    @IBOutlet weak var userNameLabel: NSTextField!
    @IBOutlet weak var dateLabel: NSTextField!
    
    @IBOutlet weak var audioFileContainer: NSView!
    @IBOutlet weak var fileInfoView: FileInfoView!
    @IBOutlet weak var audioMessageView: AudioMessageView!
    
    @IBOutlet weak var mediaTextContainer: NSStackView!
    @IBOutlet weak var messageMediaContainer: NSView!
    @IBOutlet weak var messageMediaView: MediaMessageView!
    
    @IBOutlet weak var textContainer: NSView!
    @IBOutlet weak var messageLabel: NSTextField!
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setupView()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setupView()
    }
    
    func setupView() {
        addShadow(
            location: VerticalLocation.bottom,
            color: NSColor.black,
            opacity: 0.3,
            radius: 5.0
        )
        
        fileInfoView.wantsLayer = true
        fileInfoView.layer?.backgroundColor = NSColor.Sphinx.HeaderBG.cgColor
        fileInfoView.layer?.cornerRadius = 9
    }
    
    func hideAllViews() {
        audioFileContainer.isHidden = true
        audioMessageView.isHidden = true
        fileInfoView.isHidden = true
        mediaTextContainer.isHidden = true
        messageMediaContainer.isHidden = true
        messageMediaView.isHidden = true
        textContainer.isHidden = true
    }
    
    func configureWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        delegate: ThreadHeaderViewDelegate
    ){
        hideAllViews()
        
        var mutableMessageCellState = messageCellState
        
        self.delegate = delegate
        self.messageId = mutableMessageCellState.messageId
        
        configureWith(threadOriginalMessage: mutableMessageCellState.threadOriginalMessageHeader)
        configureWith(messageMedia: mutableMessageCellState.messageMedia, mediaData: mediaData)
        configureWith(genericFile: mutableMessageCellState.genericFile, mediaData: mediaData)
        configureWith(audio: mutableMessageCellState.audio, mediaData: mediaData)
    }
    
    func configureWith(
        threadOriginalMessage: NoBubbleMessageLayoutState.ThreadOriginalMessage?
    ) {
        
        guard let threadOriginalMessage = threadOriginalMessage else {
            return
        }
        
        dateLabel.stringValue = threadOriginalMessage.timestamp
        userNameLabel.stringValue = threadOriginalMessage.senderAlias
        
        chatAvatarView.configureForUserWith(
            color: threadOriginalMessage.senderColor,
            alias: threadOriginalMessage.senderAlias,
            picture: threadOriginalMessage.senderPic,
            radius: 18.0
        )
        
        guard threadOriginalMessage.text.isNotEmpty else {
            return
        }
        
        mediaTextContainer.isHidden = false
        textContainer.isHidden = false
        
        messageLabel.stringValue = threadOriginalMessage.text
    }
    
    func configureWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia?,
        mediaData: MessageTableCellState.MediaData?
    ) {
        if let messageMedia = messageMedia {
            
            messageMediaView.configureWith(
                messageMedia: messageMedia,
                mediaData: mediaData,
                bubble: BubbleMessageLayoutState.Bubble(direction: .Incoming, grouping: .Isolated),
                and: self
            )
            
            messageMediaView.isHidden = false
            mediaTextContainer.isHidden = false
            messageMediaContainer.isHidden = false
            

            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    if messageMedia.isImage {
                        self.delegate?.shouldLoadImageDataFor?(
                            messageId: messageId,
                            and: -1
                        )
                    } else if messageMedia.isPdf {
                        self.delegate?.shouldLoadPdfDataFor?(
                            messageId: messageId,
                            and: -1
                        )
                    } else if messageMedia.isVideo {
                        self.delegate?.shouldLoadVideoDataFor?(
                            messageId: messageId,
                            and: -1
                        )
                    } else if messageMedia.isGiphy {
                        self.delegate?.shouldLoadGiphyDataFor?(
                            messageId: messageId,
                            and: -1
                        )
                    }
                }
            }
        }
    }
    
    func configureWith(
        genericFile: BubbleMessageLayoutState.GenericFile?,
        mediaData: MessageTableCellState.MediaData?
    ) {
        if let _ = genericFile {
            
            fileInfoView.configureWith(
                mediaData: mediaData,
                and: self
            )
            
            audioFileContainer.isHidden = false
            fileInfoView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadFileDataFor?(
                        messageId: messageId,
                        and: -1
                    )
                }
            }
        }
    }
    
    func configureWith(
        audio: BubbleMessageLayoutState.Audio?,
        mediaData: MessageTableCellState.MediaData?
    ) {
        if let audio = audio {
            
            audioMessageView.configureWith(
                audio: audio,
                mediaData: mediaData,
                bubble: BubbleMessageLayoutState.Bubble(direction: .Incoming, grouping: .Isolated),
                and: self
            )
            
            audioFileContainer.isHidden = false
            audioMessageView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadAudioDataFor?(
                        messageId: messageId,
                        and: -1
                    )
                }
            }
        }
    }
    
}

extension ThreadHeaderView : MediaMessageViewDelegate {
    func didTapMediaButton() {
        if let messageId = messageId {
            delegate?.didTapMediaButtonFor(messageId: messageId, and: -1)
        }
    }
}

extension ThreadHeaderView : FileInfoViewDelegate {
    func didTouchDownloadButton() {
        if let messageId = messageId {
            delegate?.didTapFileDownloadButtonFor(messageId: messageId, and: -1)
        }
    }
}

extension ThreadHeaderView : AudioMessageViewDelegate {
    func didTapPlayPauseButton() {
        if let messageId = messageId {
            delegate?.didTapPlayPauseButtonFor(messageId: messageId, and: -1)
        }
    }
}
