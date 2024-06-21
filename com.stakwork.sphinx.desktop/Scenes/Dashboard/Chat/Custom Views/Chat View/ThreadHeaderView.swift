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
    
    func shouldCloseThread()
    
    func shouldShowOptionsFor(messageId: Int, from button: NSButton)
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
    @IBOutlet weak var messageBoostView: NewMessageBoostView!
    @IBOutlet weak var messageBoostViewContainer: NSView!
    
    @IBOutlet weak var textContainer: NSView!
    @IBOutlet weak var messageLabel: MessageTextField!
    
    @IBOutlet weak var newMessageLabelScrollView: DisabledScrollView!
    @IBOutlet var newMessageLabel: NSTextView!
    @IBOutlet weak var closeButton: CustomButton!
    @IBOutlet weak var optionsButton: CustomButton!
    
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
        closeButton.cursor = .pointingHand
        optionsButton.cursor = .pointingHand
        
        addShadow(
            location: VerticalLocation.bottom,
            color: NSColor.black,
            opacity: 0.3,
            radius: 5.0
        )
        
        messageLabel.setSelectionColor(color: NSColor.getTextSelectionColor())
        messageLabel.allowsEditingTextAttributes = true
        
        fileInfoView.wantsLayer = true
        fileInfoView.layer?.backgroundColor = NSColor.Sphinx.Body.cgColor
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
        messageBoostViewContainer.isHidden = true
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
        
        if let bubble = mutableMessageCellState.bubble {
            configureWith(boosts: mutableMessageCellState.boosts, and: bubble)
        }
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
        messageLabel.isHidden = true
        newMessageLabel.isEditable = false
        
        if threadOriginalMessage.linkMatches.isEmpty && threadOriginalMessage.highlightedMatches.isEmpty {
            messageLabel.attributedStringValue = NSMutableAttributedString(string: "")
            newMessageLabel.string = threadOriginalMessage.text
            newMessageLabel.font = threadOriginalMessage.font
            messageLabel.stringValue = threadOriginalMessage.text
            messageLabel.font = threadOriginalMessage.font
        } else {
            let messageC = threadOriginalMessage.text

            let attributedString = NSMutableAttributedString(string: messageC)
            attributedString.addAttributes(
                [
                    NSAttributedString.Key.font: threadOriginalMessage.font,
                    NSAttributedString.Key.foregroundColor: NSColor.Sphinx.Text
                ]
                , range: messageC.nsRange
            )
            
            ///Highlighted text formatting
            let highlightedNsRanges = threadOriginalMessage.highlightedMatches.map {
                return $0.range
            }
            
            for (index, nsRange) in highlightedNsRanges.enumerated() {
                
                ///Subtracting the previous matches delimiter characters since they have been removed from the string
                ///Subtracting the \` characters from the length since removing the chars caused the range to be 2 less chars
                let substractionNeeded = index * 2
                let adaptedRange = NSRange(location: nsRange.location - substractionNeeded, length: nsRange.length - 2)
                
                attributedString.addAttributes(
                    [
                        NSAttributedString.Key.foregroundColor: NSColor.Sphinx.HighlightedText,
                        NSAttributedString.Key.backgroundColor: NSColor.Sphinx.HighlightedTextBackground,
                        NSAttributedString.Key.font: threadOriginalMessage.highlightedFont
                    ],
                    range: adaptedRange
                )
            }
            
            ///Links formatting
            var nsRanges = threadOriginalMessage.linkMatches.map {
                return $0.range
            }
            
            nsRanges = ChatHelper.removeDuplicatedContainedFrom(urlRanges: nsRanges)

            for nsRange in nsRanges {
                
                if let range = Range(nsRange, in: messageC) {
                    
                    var substring = String(messageC[range])
                    
                    if substring.isPubKey || substring.isVirtualPubKey {
                        substring = substring.shareContactDeepLink
                    } else if substring.starts(with: API.kVideoCallServer) {
                        substring = substring.callLinkDeepLink
                    } else if !substring.isTribeJoinLink {
                        substring = substring.withProtocol(protocolString: "http")
                    }
                     
                    if let url = URL(string: substring.withProtocol(protocolString: "http"))  {
                        attributedString.addAttributes(
                            [
                                NSAttributedString.Key.foregroundColor: NSColor.Sphinx.PrimaryBlue,
                                NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
                                NSAttributedString.Key.font: threadOriginalMessage.font,
                                NSAttributedString.Key.link: url
                            ],
                            range: nsRange
                        )

                    }
                }
            }

            messageLabel.attributedStringValue = attributedString
            messageLabel.isEnabled = true
            newMessageLabel.string = attributedString.string
            newMessageLabel.textStorage?.setAttributedString(attributedString)
        }
    }
    
    func configureWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia?,
        mediaData: MessageTableCellState.MediaData?
    ) {
        newMessageLabelScrollView.disabled = true
        
        if let messageMedia = messageMedia {
            
            messageMediaView.configureWith(
                messageMedia: messageMedia,
                mediaData: mediaData,
                bubble: BubbleMessageLayoutState.Bubble(direction: .Incoming, grouping: .Isolated),
                and: self
            )
            
            newMessageLabelScrollView.disabled = false
            messageMediaView.isHidden = false
            mediaTextContainer.isHidden = false
            messageMediaContainer.isHidden = false
            

            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    if messageMedia.isImage {
                        self.delegate?.shouldLoadImageDataFor?(
                            messageId: messageId,
                            and: NewChatTableDataSource.kThreadHeaderRowIndex
                        )
                    } else if messageMedia.isPdf {
                        self.delegate?.shouldLoadPdfDataFor?(
                            messageId: messageId,
                            and: NewChatTableDataSource.kThreadHeaderRowIndex
                        )
                    } else if messageMedia.isVideo {
                        self.delegate?.shouldLoadVideoDataFor?(
                            messageId: messageId,
                            and: NewChatTableDataSource.kThreadHeaderRowIndex
                        )
                    } else if messageMedia.isGiphy {
                        self.delegate?.shouldLoadGiphyDataFor?(
                            messageId: messageId,
                            and: NewChatTableDataSource.kThreadHeaderRowIndex
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
                        and: NewChatTableDataSource.kThreadHeaderRowIndex
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
                        and: NewChatTableDataSource.kThreadHeaderRowIndex
                    )
                }
            }
        }
    }
    
    func configureWith(
        boosts: BubbleMessageLayoutState.Boosts?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let boosts = boosts {
            messageBoostView.configureWith(boosts: boosts, and: bubble, isThreadHeader: true)
            messageBoostViewContainer.isHidden = false
        }
    }
    
    @IBAction func optionsButtonClicked(_ sender: Any) {
        if let button = sender as? NSButton, let messageId = messageId {
            delegate?.shouldShowOptionsFor(messageId: messageId, from: button)
        }
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        delegate?.shouldCloseThread()
    }
}

extension ThreadHeaderView : MediaMessageViewDelegate {
    func didTapMediaButton() {
        if let messageId = messageId {
            delegate?.didTapMediaButtonFor(messageId: messageId, and: NewChatTableDataSource.kThreadHeaderRowIndex)
        }
    }
}

extension ThreadHeaderView : FileInfoViewDelegate {
    func didTouchDownloadButton() {
        if let messageId = messageId {
            delegate?.didTapFileDownloadButtonFor(messageId: messageId, and: NewChatTableDataSource.kThreadHeaderRowIndex)
        }
    }
}

extension ThreadHeaderView : AudioMessageViewDelegate {
    func didTapPlayPauseButton() {
        if let messageId = messageId {
            delegate?.didTapPlayPauseButtonFor(messageId: messageId, and: NewChatTableDataSource.kThreadHeaderRowIndex)
        }
    }
}
