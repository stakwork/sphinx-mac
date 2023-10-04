//
//  ThreadCollectionView+GeneralSetup.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 27/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension ThreadCollectionViewItem {
    func setupViews() {
        messageLabel.isSelectable = false
        messageLabel.maximumNumberOfLines = 2
        messageLabel.setSelectionColor(color: NSColor.getTextSelectionColor())
        messageLabel.allowsEditingTextAttributes = true
        
        lastReplyMessageLabel.isSelectable = false
        lastReplyMessageLabel.setSelectionColor(color: NSColor.getTextSelectionColor())
        lastReplyMessageLabel.allowsEditingTextAttributes = true
        
        receivedArrow.drawReceivedBubbleArrow(color: NSColor.Sphinx.ReceivedMsgBG)
        sentArrow.drawSentBubbleArrow(color: NSColor.Sphinx.SentMsgBG)
        
        let lineFrame = CGRect(
            x: 0.0,
            y: 0,
            width: 3,
            height: self.view.frame.size.height
        )

        let rightLineLayer = rightLineContainer.getVerticalDottedLine(
            color: NSColor.Sphinx.WashedOutReceivedText,
            frame: lineFrame
        )
        rightLineContainer.wantsLayer = true
        rightLineContainer.layer?.addSublayer(rightLineLayer)

        let leftLineLayer = leftLineContainer.getVerticalDottedLine(
            color: NSColor.Sphinx.WashedOutReceivedText,
            frame: lineFrame
        )
        leftLineContainer.wantsLayer = true
        leftLineContainer.layer?.addSublayer(leftLineLayer)
        
        mediaMessageContainer.wantsLayer = true
        mediaMessageContainer.layer?.masksToBounds = false
    }
    
    func configureWidth() {
        widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumThreadBubbleWidth
        self.view.layoutSubtreeIfNeeded()
    }
    
    func hideAllSubviews() {
        textMessageView.isHidden = true
        mediaMessageContainer.isHidden = true
        mediaMessageView.isHidden = true
        fileDetailsView.isHidden = true
        audioMessageView.isHidden = true
        
        lastReplyTextMessageView.isHidden = true
        lastReplyMediaMessageView.isHidden = true
        lastReplyFileDetailsView.isHidden = true
        lastReplyAudioMessageView.isHidden = true
        
        threadRepliesView.isHidden = true
        threadLastMessageHeader.isHidden = true
    }
}
