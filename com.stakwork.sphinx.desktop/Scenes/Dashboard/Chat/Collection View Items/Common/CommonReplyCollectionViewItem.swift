//
//  CommonMessageCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 15/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonReplyCollectionViewItem : CommonChatCollectionViewItem {
    var replyBubbleView : MessageBubbleView? = nil
    
    func addReplyBubble(relativeTo view: NSView) {
        if replyBubbleView == nil {
            replyBubbleView = MessageBubbleView()
            replyBubbleView?.isHidden = true
            self.view.addSubview(replyBubbleView!)
            
            replyBubbleView!.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint(item: replyBubbleView!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: replyBubbleView!, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: replyBubbleView!, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: replyBubbleView!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: MessageReplyView.kMessageReplyHeight).isActive = true
        
            replyBubbleView?.superview?.layoutSubtreeIfNeeded()
        }
    }
    
    func configureReplyBubble(bubbleView: NSView, bubbleSize: CGSize, incoming: Bool) {
        guard let messageRow = messageRow, let message = messageRow.transactionMessage, message.isReply() else {
            replyBubbleView?.isHidden = true
            return
        }
        
        addReplyBubble(relativeTo: bubbleView)
        
        if let replyBubbleView = replyBubbleView {
            let replyingTo = message.getReplyingTo()
            let replySize = CGSize(width: bubbleSize.width, height: MessageReplyView.kMessageReplyHeight)
            var viewFrame: CGRect = CGRect.zero
            let consecutiveBubbles = MessageBubbleView.ConsecutiveBubbles(previousBubble: false, nextBubble: true)

            if incoming {
                replyBubbleView.showIncomingEmptyBubble(messageRow: messageRow, size: replySize, consecutiveBubbles: consecutiveBubbles)
                let leftMargin = Constants.kBubbleReceivedArrowMargin
                viewFrame = CGRect(x: leftMargin, y: 0, width: bubbleSize.width - leftMargin, height: replyBubbleView.frame.height)
            } else {
                replyBubbleView.showOutgoingEmptyBubble(messageRow: messageRow, size: replySize, consecutiveBubbles: consecutiveBubbles)
                let rightMargin = Constants.kBubbleSentArrowMargin
                viewFrame = CGRect(x: 0, y: 0, width: bubbleSize.width - rightMargin, height: replyBubbleView.frame.height)
            }
            
            replyBubbleView.removeAllSubviews()

            let messageReplyView = MessageReplyView(frame: viewFrame)
            messageReplyView.configureForRow(with: replyingTo, and: self, isIncoming: incoming)
            
            replyBubbleView.addSubview(messageReplyView)
            replyBubbleView.isHidden = false
        }
    }
}

extension CommonReplyCollectionViewItem : SearchTopViewDelegate {
    func shouldScrollTo(message: TransactionMessage) {
        delegate?.shouldScrollTo(message: message)
    }
}
