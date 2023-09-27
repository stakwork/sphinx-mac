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
        messageMedia: BubbleMessageLayoutState.MessageMedia?,
        mediaData: MessageTableCellState.MediaData?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let messageMedia = messageMedia {
            
            mediaMessageView.configureWith(
                messageMedia: messageMedia,
                mediaData: mediaData,
                bubble: bubble,
                and: self
            )
            mediaMessageView.isHidden = false
            
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
    
    func configureWith(
        messageCellState: MessageTableCellState,
        searchingTerm: String?,
        linkData: MessageTableCellState.LinkData? = nil,
        tribeData: MessageTableCellState.TribeData? = nil,
        collectionViewWidth: CGFloat
    ) {
        var mutableMessageCellState = messageCellState
        
        if let messageContent = mutableMessageCellState.messageContent {
            
            let labelHeight = ChatHelper.getTextMessageHeightFor(
                mutableMessageCellState,
                linkData: linkData,
                tribeData: tribeData,
                collectionViewWidth: collectionViewWidth
            )
            
            labelHeightConstraint.constant = labelHeight
            textMessageView.superview?.layoutSubtreeIfNeeded()
            
            if messageContent.linkMatches.isEmpty && searchingTerm == nil {
                messageLabel.attributedStringValue = NSMutableAttributedString(string: "")

                messageLabel.stringValue = messageContent.text ?? ""
                messageLabel.font = messageContent.font
            } else {
                let messageC = messageContent.text ?? ""
                let term = searchingTerm ?? ""

                let attributedString = NSMutableAttributedString(string: messageC)
                attributedString.addAttributes(
                    [
                        NSAttributedString.Key.font: messageContent.font,
                        NSAttributedString.Key.foregroundColor: NSColor.Sphinx.Text
                    ]
                    , range: messageC.nsRange
                )

                let searchingTermRange = (messageC.lowercased() as NSString).range(of: term.lowercased())
                attributedString.addAttributes(
                    [
                        NSAttributedString.Key.backgroundColor: NSColor.Sphinx.PrimaryGreen
                    ]
                    , range: searchingTermRange
                )
                
                var nsRanges = messageContent.linkMatches.map {
                    return $0.range
                }
                
                nsRanges = ChatHelper.removeDuplicatedContainedFrom(urlRanges: nsRanges)

                for nsRange in nsRanges {
                    
                    if let text = messageContent.text, let range = Range(nsRange, in: text) {
                        
                        var substring = String(text[range])
                        
                        if substring.isPubKey || substring.isVirtualPubKey {
                            substring = substring.shareContactDeepLink
                        }
                         
                        if let url = URL(string: substring)  {
                            attributedString.setAttributes(
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

                messageLabel.attributedStringValue = attributedString
                messageLabel.isEnabled = true
            }
            
            textMessageView.isHidden = false
            
            if let messageId = messageId, messageContent.shouldLoadPaidText {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadTextDataFor(
                        messageId: messageId,
                        and: self.rowIndex
                    )
                }
            }
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
            
//            if let messageId = messageId, mediaData == nil {
//                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
//                DispatchQueue.global().asyncAfter(deadline: delayTime) {
//                    self.delegate?.shouldLoadAudioDataFor(
//                        messageId: messageId,
//                        and: self.rowIndex
//                    )
//                }
//            }
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
            
//            if let messageId = messageId, mediaData == nil {
//                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
//                DispatchQueue.global().asyncAfter(deadline: delayTime) {
//                    if messageMedia.isImage {
//                        self.delegate?.shouldLoadImageDataFor(
//                            messageId: messageId,
//                            and: self.rowIndex
//                        )
//                    } else if messageMedia.isPdf {
//                        self.delegate?.shouldLoadPdfDataFor(
//                            messageId: messageId,
//                            and: self.rowIndex
//                        )
//                    } else if messageMedia.isVideo {
//                        self.delegate?.shouldLoadVideoDataFor(
//                            messageId: messageId,
//                            and: self.rowIndex
//                        )
//                    } else if messageMedia.isGiphy {
//                        self.delegate?.shouldLoadGiphyDataFor(
//                            messageId: messageId,
//                            and: self.rowIndex
//                        )
//                    }
//                }
//            }
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
            
//            if let messageId = messageId, mediaData == nil {
//                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
//                DispatchQueue.global().asyncAfter(deadline: delayTime) {
//                    self.delegate?.shouldLoadFileDataFor(
//                        messageId: messageId,
//                        and: self.rowIndex
//                    )
//                }
//            }
        }
    }
    
    func configureLastReplyWith(
        messageCellState: MessageTableCellState,
        searchingTerm: String?,
        linkData: MessageTableCellState.LinkData? = nil,
        tribeData: MessageTableCellState.TribeData? = nil,
        collectionViewWidth: CGFloat
    ) {
        var mutableMessageCellState = messageCellState
        
        if let messageContent = mutableMessageCellState.messageContent {
            
            let labelHeight = ChatHelper.getTextMessageHeightFor(
                mutableMessageCellState,
                linkData: linkData,
                tribeData: tribeData,
                collectionViewWidth: collectionViewWidth
            )
            
            lastReplyLabelHeightConstraint.constant = labelHeight
            lastReplyTextMessageView.superview?.layoutSubtreeIfNeeded()
            
            if messageContent.linkMatches.isEmpty && searchingTerm == nil {
                lastReplyMessageLabel.attributedStringValue = NSMutableAttributedString(string: "")

                lastReplyMessageLabel.stringValue = messageContent.text ?? ""
                lastReplyMessageLabel.font = messageContent.font
            } else {
                let messageC = messageContent.text ?? ""
                let term = searchingTerm ?? ""

                let attributedString = NSMutableAttributedString(string: messageC)
                attributedString.addAttributes(
                    [
                        NSAttributedString.Key.font: messageContent.font,
                        NSAttributedString.Key.foregroundColor: NSColor.Sphinx.Text
                    ]
                    , range: messageC.nsRange
                )

                let searchingTermRange = (messageC.lowercased() as NSString).range(of: term.lowercased())
                attributedString.addAttributes(
                    [
                        NSAttributedString.Key.backgroundColor: NSColor.Sphinx.PrimaryGreen
                    ]
                    , range: searchingTermRange
                )
                
                var nsRanges = messageContent.linkMatches.map {
                    return $0.range
                }
                
                nsRanges = ChatHelper.removeDuplicatedContainedFrom(urlRanges: nsRanges)

                for nsRange in nsRanges {
                    
                    if let text = messageContent.text, let range = Range(nsRange, in: text) {
                        
                        var substring = String(text[range])
                        
                        if substring.isPubKey || substring.isVirtualPubKey {
                            substring = substring.shareContactDeepLink
                        }
                         
                        if let url = URL(string: substring)  {
                            attributedString.setAttributes(
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

                lastReplyMessageLabel.attributedStringValue = attributedString
                lastReplyMessageLabel.isEnabled = true
            }
            
            lastReplyTextMessageView.isHidden = false
            
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
}
