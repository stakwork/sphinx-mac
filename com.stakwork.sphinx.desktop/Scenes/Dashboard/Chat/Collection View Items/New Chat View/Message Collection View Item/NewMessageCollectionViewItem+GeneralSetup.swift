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
//        bubbleAllView.layer.cornerRadius = MessageTableCellState.kBubbleCornerRadius
//        leftPaymentDot.layer.cornerRadius = leftPaymentDot.frame.height / 2
//        rightPaymentDot.layer.cornerRadius = rightPaymentDot.frame.height / 2

//        paidAttachmentView.roundCorners(
//            corners: [.bottomLeft, .bottomRight],
//            radius: MessageTableCellState.kBubbleCornerRadius,
//            viewBounds: CGRect(
//                origin: CGPoint.zero,
//                size: CGSize(
//                    width: (UIScreen.main.bounds.width - (MessageTableCellState.kRowLeftMargin + MessageTableCellState.kRowRightMargin)) * (MessageTableCellState.kBubbleWidthPercentage),
//                    height: MessageTableCellState.kSendPaidContentButtonHeight
//                )
//            )
//        )

        receivedArrow.drawReceivedBubbleArrow(color: NSColor.Sphinx.ReceivedMsgBG)
        sentArrow.drawSentBubbleArrow(color: NSColor.Sphinx.SentMsgBG)
        
//        let lineFrame = CGRect(x: 0.0, y: 0, width: 3, height: contentView.frame.size.height)
//
//        let rightLineLayer = rightLineContainer.getVerticalDottedLine(color: UIColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
//        rightLineContainer.layer.addSublayer(rightLineLayer)
//
//        let leftLineLayer = leftLineContainer.getVerticalDottedLine(color: UIColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
//        leftLineContainer.layer.addSublayer(leftLineLayer)
    }
    
    func configureViewsWidthWith(
        messageCellState: MessageTableCellState,
        linkData: MessageTableCellState.LinkData?,
        tribeData: MessageTableCellState.TribeData?
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
        } else if let _ = mutableCellState.callLink {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumCallLinkBubbleWidth
        } else if let _ = mutableCellState.podcastBoost {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumPodcastBoostBubbleWidth
        } else if let _ = mutableCellState.genericFile {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumGenericFileBubbleWidth
        } else if let _ = linkData {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumLinksBubbleWidth
        } else if let _ = tribeData {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumLinksBubbleWidth
        } else {
            widthConstraint.constant = CommonNewMessageCollectionViewitem.kMaximumLinksBubbleWidth
        }
        
        self.view.layoutSubtreeIfNeeded()
    }
    
    func hideAllSubviews() {
        textMessageView.isHidden = true
//        invoicePaymentView.isHidden = true
//        invoiceView.isHidden = true
        messageReplyView.isHidden = true
//        sentPaidDetailsView.isHidden = true
//        paidTextMessageView.isHidden = true
        directPaymentView.isHidden = true
        mediaMessageView.isHidden = true
        fileDetailsView.isHidden = true
//        audioMessageView.isHidden = true
//        podcastAudioView.isHidden = true
        callLinkView.isHidden = true
        podcastBoostView.isHidden = true
//        botResponseView.isHidden = true
//        textMessageView.isHidden = true
        tribeLinkPreviewView.isHidden = true
        contactLinkPreviewView.isHidden = true
        linkPreviewView.isHidden = true
        messageBoostView.isHidden = true
//        paidAttachmentView.isHidden = true
    }
}
