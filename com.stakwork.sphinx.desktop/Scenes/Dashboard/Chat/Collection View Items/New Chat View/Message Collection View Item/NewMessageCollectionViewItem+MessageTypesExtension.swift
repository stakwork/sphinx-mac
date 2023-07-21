//
//  NewMessageCollectionViewItem+MessageTypesExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension NewMessageCollectionViewItem {
    
    func configureWith(
        messageReply: BubbleMessageLayoutState.MessageReply?,
        and bubble: BubbleMessageLayoutState.Bubble
    ) {
        if let messageReply = messageReply {
            messageReplyView.configureWith(messageReply: messageReply, and: bubble, delegate: self)
            messageReplyView.isHidden = false
        }
    }
    
    func configureWith(
        messageContent: BubbleMessageLayoutState.MessageContent?,
        searchingTerm: String?
    ) {
//        if let messageContent = messageContent {
//            messageLabel.stringValue = messageContent.text ?? ""
//            messageLabel.font = messageContent.font
//        }
        
        urlRanges = []

        if let messageContent = messageContent {
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

                for match in messageContent.linkMatches {

                    attributedString.setAttributes(
                        [
                            NSAttributedString.Key.foregroundColor: NSColor.Sphinx.PrimaryBlue,
                            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
                            NSAttributedString.Key.font: messageContent.font
                        ],
                        range: match.range
                    )

                    urlRanges.append(match.range)
                }

                messageLabel.attributedStringValue = attributedString
//                messageLabel.isUserInteractionEnabled = true
            }
        }

//        let tap = UITapGestureRecognizer(target: self, action: #selector(labelTapped(gesture:)))

//        if urlRanges.isEmpty {
//            messageLabel.removeGestureRecognizer(tap)
//        } else {
//            messageLabel.addGestureRecognizer(tap)
//        }
    }
    
    func configureWith(
        webLink: BubbleMessageLayoutState.WebLink?,
        linkData: MessageTableCellState.LinkData?
    ) {
        if let _ = webLink {
            if let linkData = linkData {
                if !linkData.failed {
                    linkPreviewView.configureWith(linkData: linkData, delegate: self)
                    linkPreviewView.isHidden = false
                }
            } else if let messageId = messageId {
                let delayTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.global().asyncAfter(deadline: delayTime) {
                    self.delegate?.shouldLoadLinkDataFor(
                        messageId: messageId,
                        and: self.rowIndex
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
            messageBoostView.configureWith(boosts: boosts, and: bubble)
            messageBoostView.isHidden = false
        }
    }
}
