//
//  NewMessageCollectionViewItem+GeneralSetup.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension NewMessageCollectionViewItem {
    func setupViews() {
        messageLabel.setSelectionColor(color: NSColor.getTextSelectionColor())
        messageLabel.allowsEditingTextAttributes = true

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
        
        sentMessageMenuButton.cursor = .pointingHand
        receivedMessageMenuButton.cursor = .pointingHand
    }
    
    func configureViewsWidthWith(
        messageCellState: MessageTableCellState,
        linkData: MessageTableCellState.LinkData?,
        tribeData: MessageTableCellState.TribeData?,
        webViewData: MessageTableCellState.BotWebViewData?
    ) {
        var mutableCellState = messageCellState
        
        if let _ = mutableCellState.directPayment {
            var width: CGFloat = 0
            
            if let _ = mutableCellState.messageMedia {
                width = CommonNewMessageCollectionViewitem.kMaximumDirectPaymentWithMediaBubbleWidth
            } else if let _ = mutableCellState.messageContent {
                width = CommonNewMessageCollectionViewitem.kMaximumDirectPaymentWithTextBubbleWidth
            } else {
                width = CommonNewMessageCollectionViewitem.kMaximumDirectPaymentBubbleWidth
            }
            
            widthConstraint.constant = width
            
        } else if let _ = mutableCellState.messageMedia {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumMediaBubbleWidth
        } else if let _ = mutableCellState.audio {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumAudioBubbleWidth
        } else if let _ = mutableCellState.podcastComment {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumPodcastAudioBubbleWidth
        } else if let _ = mutableCellState.callLink {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumCallLinkBubbleWidth
        } else if let _ = mutableCellState.podcastBoost {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumPodcastBoostBubbleWidth
        } else if let _ = mutableCellState.genericFile {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumGenericFileBubbleWidth
        } else if let _ = mutableCellState.contactLink {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumLinksBubbleWidth
        } else if let _ = linkData {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumLinksBubbleWidth
        } else if let _ = tribeData {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumLinksBubbleWidth
        } else if let _ = mutableCellState.botHTMLContent {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumWebViewBubbleWidth
        } else if let _ = webViewData {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumWebViewBubbleWidth
        } else if let _ = mutableCellState.messageContent, let _ = mutableCellState.paidContent {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumPaidTextViewBubbleWidth
        } else if let _ = mutableCellState.invoice {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumInvoiceBubbleWidth
        } else if let _ = mutableCellState.payment {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumInvoiceBubbleWidth
        } else {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumLabelBubbleWidth
        }
        
        self.view.layoutSubtreeIfNeeded()
    }
    
    func hideAllSubviews() {
        textMessageView.isHidden = true
        invoicePaymentView.isHidden = true
        invoiceView.isHidden = true
        messageReplyView.isHidden = true
        sentPaidDetailsView.isHidden = true
        paidTextMessageView.isHidden = true
        directPaymentView.isHidden = true
        mediaMessageView.isHidden = true
        fileDetailsView.isHidden = true
        audioMessageView.isHidden = true
        podcastAudioView.isHidden = true
        callLinkView.isHidden = true
        podcastBoostView.isHidden = true
        botResponseView.isHidden = true
        tribeLinkPreviewView.isHidden = true
        contactLinkPreviewView.isHidden = true
        linkPreviewView.isHidden = true
        messageBoostView.isHidden = true
        paidAttachmentView.isHidden = true
    }
}
