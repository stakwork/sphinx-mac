//
//  NewOnlyTextMessageCollectionViewitem+LayoutExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension NewOnlyTextMessageCollectionViewitem {
    func configureWith(
        statusHeader: BubbleMessageLayoutState.StatusHeader?
    ) {
        if let statusHeader = statusHeader {
            statusHeaderView.configureWith(
                statusHeader: statusHeader,
                uploadProgressData: nil
            )
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
                    [NSAttributedString.Key.font: messageContent.font], range: messageC.nsRange
                )

                let searchingTermRange = (messageC.lowercased() as NSString).range(of: term.lowercased())
                attributedString.addAttributes([NSAttributedString.Key.backgroundColor: NSColor.Sphinx.PrimaryGreen], range: searchingTermRange)

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
        avatarImage: BubbleMessageLayoutState.AvatarImage?,
        isPreload: Bool
    ) {
        if let avatarImage = avatarImage {
            chatAvatarView.configureForUserWith(
                color: avatarImage.color,
                alias: avatarImage.alias,
                picture: avatarImage.imageUrl,
                radius: kChatAvatarHeight / 2,
                image: avatarImage.image,
                isPreload: isPreload
            )
            
//            chatAvatarView.configureForUserWith(
//                color: avatarImage.color,
//                alias: avatarImage.alias,
//                picture: avatarImage.imageUrl,
//                image: avatarImage.image,
//                and: self
//            )
        } else {
            chatAvatarView.resetView()
        }
    }
    
    func configureWith(
        bubble: BubbleMessageLayoutState.Bubble
    ) {
        configureWith(direction: bubble.direction)
        configureWith(bubbleState: bubble.grouping, direction: bubble.direction)
    }
    
    func configureWith(
        direction: MessageTableCellState.MessageDirection
    ) {
        let isOutgoing = direction.isOutgoing()
        
        sentMessageMargingView.isHidden = !isOutgoing
        receivedMessageMarginView.isHidden = isOutgoing
        
        receivedArrow.isHidden = isOutgoing
        sentArrow.isHidden = !isOutgoing
        
        messageLabelLeadingConstraint.priority = NSLayoutConstraint.Priority(isOutgoing ? 1 : 1000)
        messageLabelTrailingConstraint.priority = NSLayoutConstraint.Priority(isOutgoing ? 1000 : 1)
        
        let bubbleColor = isOutgoing ? NSColor.Sphinx.SentMsgBG : NSColor.Sphinx.ReceivedMsgBG
        bubbleOnlyText.fillColor = bubbleColor
        
        statusHeaderView.configureWith(direction: direction)
    }
    
    func configureWith(
        bubbleState: MessageTableCellState.BubbleState,
        direction: MessageTableCellState.MessageDirection
    ) {
        let outgoing = direction == .Outgoing
        
        switch (bubbleState) {
        case .Isolated:
            chatAvatarContainerView.alphaValue = outgoing ? 0.0 : 1.0
            statusHeaderViewContainer.isHidden = false
            
            receivedArrow.alphaValue = 1.0
            sentArrow.alphaValue = 1.0
            break
        case .First:
            chatAvatarContainerView.alphaValue = outgoing ? 0.0 : 1.0
            statusHeaderViewContainer.isHidden = false
            
            receivedArrow.alphaValue = 1.0
            sentArrow.alphaValue = 1.0
            break
        case .Middle:
            chatAvatarContainerView.alphaValue = 0.0
            statusHeaderViewContainer.isHidden = true
            
            receivedArrow.alphaValue = 0.0
            sentArrow.alphaValue = 0.0
            break
        case .Last:
            chatAvatarContainerView.alphaValue = 0.0
            statusHeaderViewContainer.isHidden = true
            
            receivedArrow.alphaValue = 0.0
            sentArrow.alphaValue = 0.0
            break
        case .Empty:
            break
        }
    }
    
    func configureWith(
        invoiceLines: BubbleMessageLayoutState.InvoiceLines
    ) {
//        switch (invoiceLines.linesState) {
//        case .None:
//            leftLineContainer.isHidden = true
//            rightLineContainer.isHidden = true
//            break
//        case .Left:
//            leftLineContainer.isHidden = false
//            rightLineContainer.isHidden = true
//            break
//        case .Right:
//            leftLineContainer.isHidden = true
//            rightLineContainer.isHidden = false
//            break
//        case .Both:
//            leftLineContainer.isHidden = false
//            rightLineContainer.isHidden = false
//            break
//        }
    }
}
