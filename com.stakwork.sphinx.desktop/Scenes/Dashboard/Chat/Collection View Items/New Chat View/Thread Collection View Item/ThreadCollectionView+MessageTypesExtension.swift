//
//  ThreadCollectionView+MessageTypesExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 27/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension ThreadCollectionViewItem {
    
    func configureWith(
        threadMessages: BubbleMessageLayoutState.ThreadMessages?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let threadMessages = threadMessages {
            threadRepliesView.configureWith(
                threadMessages: threadMessages,
                direction: bubble.direction
            )
            
            threadRepliesView.isHidden = false
        }
    }
    
    func configureWith(
        threadLastReply: BubbleMessageLayoutState.ThreadLastReply?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let threadLastReply = threadLastReply {
            threadLastMessageHeader.configureWith(threadLastReply: threadLastReply)
            threadLastMessageHeader.isHidden = false
        }
    }
    
    func configureWith(
        audio: BubbleMessageLayoutState.Audio?,
        mediaData: MessageTableCellState.MediaData?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let audio = audio {
            audioMessageView.configureWith(
                audio: audio,
                mediaData: mediaData,
                bubble: bubble,
                and: self
            )
            audioMessageView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadAudioDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func configureWith(
        originalMessageMedia: BubbleMessageLayoutState.MessageMedia?,
        mediaData: MessageTableCellState.MediaData?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let originalMessageMedia = originalMessageMedia {
            
            mediaMessageView.configureWith(
                messageMedia: originalMessageMedia,
                mediaData: mediaData,
                bubble: bubble,
                and: self,
                isThreadRow: true
            )
            mediaMessageView.isHidden = false
            mediaMessageContainer.isHidden = false
            
            mediaMessageView.mediaButton.isEnabled = false
            
            if let originalMessageId = originalMessageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    if originalMessageMedia.isImage {
                        self.delegate?.shouldLoadImageDataFor(
                            messageId: originalMessageId,
                            and: self.rowIndex
                        )
                    } else if originalMessageMedia.isPdf {
                        self.delegate?.shouldLoadPdfDataFor(
                            messageId: originalMessageId,
                            and: self.rowIndex
                        )
                    } else if originalMessageMedia.isVideo {
                        self.delegate?.shouldLoadVideoDataFor(
                            messageId: originalMessageId,
                            and: self.rowIndex
                        )
                    } else if originalMessageMedia.isGiphy {
                        self.delegate?.shouldLoadGiphyDataFor(
                            messageId: originalMessageId,
                            and: self.rowIndex
                        )
                    }
                }
            }
        }
    }
    
    func configureWith(
        originalMessageAudio: BubbleMessageLayoutState.Audio?,
        mediaData: MessageTableCellState.MediaData?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let originalMessageAudio = originalMessageAudio {
            audioMessageView.configureWith(
                audio: originalMessageAudio,
                mediaData: mediaData,
                bubble: bubble,
                and: self
            )
            audioMessageView.isHidden = false
            
            if let originalMessageId = originalMessageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadAudioDataFor(
                        messageId: originalMessageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func configureWith(
        originalMessaggeGenericFile: BubbleMessageLayoutState.GenericFile?,
        mediaData: MessageTableCellState.MediaData?
    ) {
        if let _ = originalMessaggeGenericFile {
            
            fileDetailsView.configureWith(
                mediaData: mediaData,
                and: self
            )
            
            fileDetailsView.isHidden = false
            
            if let originalMessageId = originalMessageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadFileDataFor(
                        messageId: originalMessageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func configureWith(
        genericFile: BubbleMessageLayoutState.GenericFile?,
        mediaData: MessageTableCellState.MediaData?
    ) {
        if let _ = genericFile {
            
            fileDetailsView.configureWith(
                mediaData: mediaData,
                and: self
            )
            
            fileDetailsView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadFileDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func configureOriginalMessageTextWith(
        threadMessage: BubbleMessageLayoutState.ThreadMessages?,
        searchingTerm: String?,
        collectionViewWidth: CGFloat
    ) {
        if let originalMessage = threadMessage?.originalMessage, let text = originalMessage.text, text.isNotEmpty {
            
            let labelHeight = ChatHelper.getThreadOriginalTextMessageHeightFor(
                text,
                collectionViewWidth: collectionViewWidth,
                maxHeight: Constants.kMessageLineHeight * 2
            )
            
            labelHeightConstraint.constant = labelHeight
            textMessageView.superview?.layoutSubtreeIfNeeded()
            
            messageLabel.stringValue = text
            messageLabel.font = originalMessage.font
            
            textMessageView.isHidden = false
            
//            if let messageId = messageId, messageContent.shouldLoadPaidText {
//                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
//                DispatchQueue.global().asyncAfter(deadline: delayTime) {
//                    self.delegate?.shouldLoadTextDataFor(
//                        messageId: messageId,
//                        and: self.rowIndex
//                    )
//                }
//            }
        }
    }
    
    func configureLastReplyWith(
        messageContent: BubbleMessageLayoutState.MessageContent?,
        searchingTerm: String?,
        collectionViewWidth: CGFloat
    ) {
        if let messageContent = messageContent, let text = messageContent.text, text.isNotEmpty {
            
            let labelHeight = ChatHelper.getThreadOriginalTextMessageHeightFor(
                text,
                collectionViewWidth: collectionViewWidth,
                highlightedMatches: messageContent.highlightedMatches
            )
            
            lastReplyLabelHeightConstraint.constant = labelHeight
            textMessageView.superview?.layoutSubtreeIfNeeded()
            
            lastReplyTextMessageView.isHidden = false
            
            if messageContent.linkMatches.isEmpty && messageContent.highlightedMatches.isEmpty && searchingTerm == nil {
                lastReplyMessageLabel.attributedStringValue = NSMutableAttributedString(string: "")

                lastReplyMessageLabel.stringValue = messageContent.text ?? ""
                lastReplyMessageLabel.font = messageContent.font
            } else {
                let messageC = messageContent.text ?? ""

                let attributedString = NSMutableAttributedString(string: messageC)
                attributedString.addAttributes(
                    [
                        NSAttributedString.Key.font: messageContent.font,
                        NSAttributedString.Key.foregroundColor: NSColor.Sphinx.Text
                    ]
                    , range: messageC.nsRange
                )
                
                ///Highlighted text formatting
                let highlightedNsRanges = messageContent.highlightedMatches.map {
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
                            NSAttributedString.Key.font: messageContent.highlightedFont
                        ],
                        range: adaptedRange
                    )
                }
                
                ///Links formatting
                var nsRanges = messageContent.linkMatches.map {
                    return $0.range
                }
                
                nsRanges = ChatHelper.removeDuplicatedContainedFrom(urlRanges: nsRanges)

                for nsRange in nsRanges {
                    
                    if let text = messageContent.text, let range = Range(nsRange, in: text) {
                        
                        var substring = String(text[range])
                        
                        if substring.isPubKey || substring.isVirtualPubKey {
                            substring = substring.shareContactDeepLink
                        } else if substring.starts(with: API.kVideoCallServer) {
                            substring = substring.callLinkDeepLink
                        } else if !substring.isTribeJoinLink {
                            substring = substring.withProtocol(protocolString: "http")
                        }
                         
                        if let url = URL(string: substring)  {
                            attributedString.addAttributes(
                                [
                                    NSAttributedString.Key.foregroundColor: NSColor.Sphinx.PrimaryBlue,
                                    NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
                                    NSAttributedString.Key.font: messageContent.font,
                                    NSAttributedString.Key.link: url
                                ],
                                range: nsRange
                            )

                        }
                    }
                }
                
                ///Search term formatting
                let term = searchingTerm ?? ""
                let searchingTermRange = (messageC.lowercased() as NSString).range(of: term.lowercased())
                attributedString.addAttributes(
                    [
                        NSAttributedString.Key.backgroundColor: NSColor.Sphinx.PrimaryGreen
                    ]
                    , range: searchingTermRange
                )

                lastReplyMessageLabel.attributedStringValue = attributedString
                lastReplyMessageLabel.isEnabled = true
            }
            
//            if let messageId = messageId, messageContent.shouldLoadPaidText {
//                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
//                DispatchQueue.global().asyncAfter(deadline: delayTime) {
//                    self.delegate?.shouldLoadTextDataFor(
//                        messageId: messageId,
//                        and: self.rowIndex
//                    )
//                }
//            }
        }
    }
    
    func configureLastReplyWith(
        audio: BubbleMessageLayoutState.Audio?,
        mediaData: MessageTableCellState.MediaData?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let audio = audio {
            lastReplyAudioMessageView.configureWith(
                audio: audio,
                mediaData: mediaData,
                bubble: bubble,
                and: self
            )
            lastReplyAudioMessageView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadAudioDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
    
    func configureLastReplyWith(
        messageMedia: BubbleMessageLayoutState.MessageMedia?,
        mediaData: MessageTableCellState.MediaData?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let messageMedia = messageMedia {
            
            lastReplyMediaMessageView.configureWith(
                messageMedia: messageMedia,
                mediaData: mediaData,
                bubble: bubble,
                and: self
            )
            lastReplyMediaMessageView.isHidden = false
            lastReplyMediaMessageView.mediaButton.isEnabled = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    if messageMedia.isImage {
                        self.delegate?.shouldLoadImageDataFor(
                            messageId: messageId,
                            and: self.rowIndex
                        )
                    } else if messageMedia.isPdf {
                        self.delegate?.shouldLoadPdfDataFor(
                            messageId: messageId,
                            and: self.rowIndex
                        )
                    } else if messageMedia.isVideo {
                        self.delegate?.shouldLoadVideoDataFor(
                            messageId: messageId,
                            and: self.rowIndex
                        )
                    } else if messageMedia.isGiphy {
                        self.delegate?.shouldLoadGiphyDataFor(
                            messageId: messageId,
                            and: self.rowIndex
                        )
                    }
                }
            }
        }
    }
    
    func configureLastReplyWith(
        genericFile: BubbleMessageLayoutState.GenericFile?,
        mediaData: MessageTableCellState.MediaData?
    ) {
        if let _ = genericFile {
            
            lastReplyFileDetailsView.configureWith(
                mediaData: mediaData,
                and: self
            )
            
            lastReplyFileDetailsView.isHidden = false
            
            if let messageId = messageId, mediaData == nil {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadFileDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
        }
    }
}
