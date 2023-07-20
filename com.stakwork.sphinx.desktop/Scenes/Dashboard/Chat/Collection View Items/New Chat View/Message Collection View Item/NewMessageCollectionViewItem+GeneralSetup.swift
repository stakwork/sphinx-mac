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
    
    func configureViewsWidth(
        messageContent: BubbleMessageLayoutState.MessageContent?
    ) {
        let labelMargins = (Constants.kMargin * 2)
        let labelSizeFix: CGFloat = 10
        
        let attrs = [NSAttributedString.Key.font: Constants.kMessageFont]
        let attributedString = NSAttributedString(string: messageContent?.text ?? "", attributes: attrs)
        let textWidth = attributedString.size(forWidth: kBubbleMaxWidth - labelMargins, height: 2000).width  - labelSizeFix
        
        let desiredWidth = max(textWidth, kBubbleMinWidth - labelMargins) + labelMargins
        topViewWidthConstraint.constant = desiredWidth
        bottomViewWidthConstraint.constant = desiredWidth
        
        self.view.layoutSubtreeIfNeeded()
    }
    
    func hideAllSubviews() {
//        invoicePaymentView.isHidden = true
//        invoiceView.isHidden = true
        messageReplyView.isHidden = true
//        sentPaidDetailsView.isHidden = true
//        paidTextMessageView.isHidden = true
//        directPaymentView.isHidden = true
//        mediaContentView.isHidden = true
//        fileDetailsView.isHidden = true
//        audioMessageView.isHidden = true
//        podcastAudioView.isHidden = true
//        callLinkView.isHidden = true
//        podcastBoostView.isHidden = true
//        botResponseView.isHidden = true
//        textMessageView.isHidden = true
//        tribeLinkPreviewView.isHidden = true
//        contactLinkPreviewView.isHidden = true
        linkPreviewView.isHidden = true
//        messageBoostView.isHidden = true
//        paidAttachmentView.isHidden = true
    }
}
