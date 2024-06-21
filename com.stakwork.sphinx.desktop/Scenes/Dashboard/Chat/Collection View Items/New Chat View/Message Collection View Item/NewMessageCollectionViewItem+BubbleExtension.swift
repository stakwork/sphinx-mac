//
//  NewMessageCollectionViewItem+BubbleExtension.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension NewMessageCollectionViewItem {
    func configureWith(
        avatarImage: BubbleMessageLayoutState.AvatarImage?
    ) {
        if let avatarImage = avatarImage {
            chatAvatarView.configureForUserWith(
                color: avatarImage.color,
                alias: avatarImage.alias,
                picture: avatarImage.imageUrl,
                radius: kChatAvatarHeight / 2,
                image: avatarImage.image,
                delegate: self
            )
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
//        let textRightAligned = isOutgoing
        
        messageContentStackView.alignment = isOutgoing ? .trailing : .leading
        
        sentMessageMargingView.isHidden = !isOutgoing
        receivedMessageMarginView.isHidden = isOutgoing
        
        receivedArrow.isHidden = isOutgoing
        sentArrow.isHidden = !isOutgoing
        
//        messageLabelLeadingConstraint.priority = NSLayoutConstraint.Priority(textRightAligned ? 1 : 1000)
//        messageLabelTrailingConstraint.priority = NSLayoutConstraint.Priority(textRightAligned ? 1000 : 1)
        
        let bubbleColor = isOutgoing ? NSColor.Sphinx.SentMsgBG : NSColor.Sphinx.ReceivedMsgBG
        bubbleAllViews.fillColor = bubbleColor
        
        statusHeaderView.configureWith(direction: direction)
    }
    
    func configureWith(
        bubbleState: MessageTableCellState.BubbleState,
        direction: MessageTableCellState.MessageDirection
    ) {
        let outgoing = direction == .Outgoing
        
        receivedMessageMenuButton.isHidden = outgoing || bubbleState == MessageTableCellState.BubbleState.Empty
        sentMessageMenuButton.isHidden = !outgoing || bubbleState == MessageTableCellState.BubbleState.Empty
        
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
            chatAvatarContainerView.alphaValue = outgoing ? 0.0 : 1.0
            statusHeaderViewContainer.isHidden = false
            bubbleAllViews.fillColor = NSColor.clear
            
            receivedArrow.alphaValue = 0.0
            sentArrow.alphaValue = 0.0
            break
        }
    }
    
    func configureWith(
        invoiceLines: BubbleMessageLayoutState.InvoiceLines
    ) {
        switch (invoiceLines.linesState) {
        case .None:
            leftLineContainer.isHidden = true
            rightLineContainer.isHidden = true
            break
        case .Left:
            leftLineContainer.isHidden = false
            rightLineContainer.isHidden = true
            break
        case .Right:
            leftLineContainer.isHidden = true
            rightLineContainer.isHidden = false
            break
        case .Both:
            leftLineContainer.isHidden = false
            rightLineContainer.isHidden = false
            break
        }
    }
}
