//
//  ChatHelper.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 18/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

struct DeeplinkData{
    var feedID:String
    var itemID:String
    var timestamp:Int
}

class ChatHelper {
    public static func getSenderColorFor(message: TransactionMessage) -> NSColor {
        var key:String? = nil
        
        if !(message.chat?.isPublicGroup() ?? false) || message.senderId == 1 {
            key = "\(message.senderId)-color"
        }
        
        if let senderAlias = message.senderAlias, !senderAlias.isEmpty {
            key = "\(senderAlias.trim())-color"
        }

        if let key = key {
            return NSColor.getColorFor(key: key)
        }
        return NSColor.Sphinx.SecondaryText
    }
    
    public static func getRecipientColorFor(
        message: TransactionMessage
    ) -> NSColor {
        
        if let recipientAlias = message.recipientAlias, !recipientAlias.isEmpty {
            return NSColor.getColorFor(
                key: "\(recipientAlias.trim())-color"
            )
        }
        return NSColor.Sphinx.SecondaryText
    }
    
    public static func removeDuplicatedContainedFrom(
        urlRanges: [NSRange]
    ) -> [NSRange] {
        var ranges = urlRanges
        
        var indexesToRemove: [Int] = []
        
        for (i, ur) in ranges.enumerated() {
            for urlRange in ranges {
                if (
                    ur.lowerBound >= urlRange.lowerBound && ur.upperBound < urlRange.upperBound ||
                    ur.lowerBound > urlRange.lowerBound && ur.upperBound <= urlRange.upperBound
                ) {
                    indexesToRemove.append(i)
                }
            }
        }
        
        indexesToRemove = Array(Set(indexesToRemove))
        indexesToRemove.sort(by: >)
        
        for index in indexesToRemove {
            if ranges.count > index {
                ranges.remove(at: index)
            }
        }
        
        return ranges
    }

    func getHeightToSubstract(message: TransactionMessage) -> CGFloat {
        let shouldRemoveHeader = message.consecutiveMessages.previousMessage && !message.isFailedOrMediaExpired()
        return shouldRemoveHeader ? Constants.kRowHeaderHeight : 0
    }
    
    func processGroupedMessages(array: [TransactionMessage], referenceMessageDate: inout Date?) {
        let filteredArray = array.filter({ !$0.isMessageReaction() })
        
        for i in 0..<filteredArray.count {
            let message = filteredArray[i]
            let nextMessage = (i + 1 < filteredArray.count) ? filteredArray[i + 1] : nil
            
            if let nextMessage = nextMessage, nextMessage.id == message.id {
                continue
            }
            
            message.resetNextConsecutiveMessages()
            
            if message.isUniqueOnChat() { message.resetPreviousConsecutiveMessages() }
            nextMessage?.resetPreviousConsecutiveMessages()
            
            referenceMessageDate = (referenceMessageDate == nil) ? message.date : referenceMessageDate
            
            if (nextMessage?.isNotConsecutiveMessage() ?? false) || message.isNotConsecutiveMessage() {
                referenceMessageDate = message.date
                continue
            }
            
            if referenceMessageDate!.getMinutesDifference(from: message.messageDate) > 5 {
               referenceMessageDate = message.date
            }
            
            if nextMessage != nil {
                if message.failed() || !message.isConfirmedAsReceived() {
                    referenceMessageDate = message.date
                    message.consecutiveMessages.nextMessage = false
                    nextMessage!.consecutiveMessages.previousMessage = false
                } else if referenceMessageDate!.getMinutesDifference(from: nextMessage!.messageDate) <= 5 {
                    if message.hasSameSenderThan(message: nextMessage) {
                        message.consecutiveMessages.nextMessage = true
                        nextMessage!.consecutiveMessages.previousMessage = true
                    } else {
                        referenceMessageDate = nextMessage!.date
                    }
                }
            }
        }
    }

    func processGroupedNewMessage(array: [TransactionMessage], referenceMessageDate: inout Date?, message: TransactionMessage) {
        let filteredArray = array.filter({ !$0.isMessageReaction() })
        let previousMessage = filteredArray.last
        
        referenceMessageDate = (referenceMessageDate == nil) ? message.date : referenceMessageDate
        
        if (previousMessage?.isNotConsecutiveMessage() ?? false) || message.isNotConsecutiveMessage() {
            referenceMessageDate = message.date
            return
        }
        
        if referenceMessageDate!.getMinutesDifference(from: message.messageDate) > 5 {
            referenceMessageDate = message.date
            return
        }
        
        if previousMessage != nil && referenceMessageDate!.getMinutesDifference(from: message.messageDate) <= 5 {
            if previousMessage!.failed() || !previousMessage!.isConfirmedAsReceived() {
                referenceMessageDate = message.date
                message.consecutiveMessages.previousMessage = false
                previousMessage!.consecutiveMessages.nextMessage = false
            } else if message.hasSameSenderThan(message: previousMessage) {
                message.consecutiveMessages.previousMessage = true
                previousMessage!.consecutiveMessages.nextMessage = true
            } else {
                referenceMessageDate = message.date
            }
        }
    }
    
    func processMessagesReactionsFor(
        chat: Chat?,
        messagesArray: [TransactionMessage],
        boosts: inout [String: TransactionMessage.Reactions]
    ) {
        guard let chat = chat else {
            return
        }
        let messagesUUIDs: [String] = messagesArray.map { $0.uuid ?? "" }
        let emptyFilteredUUIDs = messagesUUIDs.filter { !$0.isEmpty }
        
        for message in TransactionMessage.getReactionsOn(chat: chat, for: emptyFilteredUUIDs) {
            processMessageReaction(
                message: message,
                owner: UserContact.getOwner(),
                contact: chat.getContact(),
                boosts: &boosts
            )
        }
    }
    
    func processMessageReaction(
        message: TransactionMessage,
        owner: UserContact?,
        contact: UserContact?,
        boosts: inout [String: TransactionMessage.Reactions]
    ) {
        if let replyUUID = message.replyUUID, let owner = UserContact.getOwner() {
            let outgoing = message.isOutgoing()
            let senderImageUrl: String? = message.getMessageSenderImageUrl(owner: owner, contact: contact)
            
            let user: (String, NSColor, String?) = (message.getMessageSenderNickname(forceNickname: true, owner: owner, contact: nil), ChatHelper.getSenderColorFor(message: message), senderImageUrl)
            let amount = message.amount?.intValue ?? 0
            
            if var reaction = boosts[replyUUID] {
                reaction.add(sats: amount, user: user, id: message.id)
                if outgoing { reaction.boosted = true }
                boosts[replyUUID] = reaction
            } else {
                boosts[replyUUID] = TransactionMessage.Reactions(totalSats: amount, users: [user.0: (user.1, user.2)], boosted: outgoing, id: message.id)
            }
        }
    }
    
    public static func getThreadListRowHeightFor(
        _ tableCellState: ThreadTableCellState
    ) -> CGFloat {
        ///No Bubble message views
        var mutableTableCellState = tableCellState
        let kTopMargin: CGFloat = 44.0
        let kBottomMargin: CGFloat = 52.0
        
        let kElementMargin: CGFloat = 12.0
        let kMessageLineHeight: CGFloat = 20
        let kTextWidth: CGFloat = 376
        
        var textHeight: CGFloat = 0
        var viewsHeight: CGFloat = 0.0
        
        
        if let originalThreadMessage = mutableTableCellState.threadMessagesState?.orignalThreadMessage {
            
            if originalThreadMessage.text.isNotEmpty {
                textHeight = getThreadListTextMessageHeightFor(
                    originalThreadMessage.text,
                    width: kTextWidth,
                    maxHeight: kMessageLineHeight * 2,
                    font: NSFont.getThreadListFont()
                ) + kElementMargin
            }
        }
        
        if let _ = mutableTableCellState.audio {
            viewsHeight += AudioMessageView.kThreadsListViewHeight
        }
        
        if let _ = mutableTableCellState.messageMedia {
            viewsHeight += MediaMessageView.kThreadsListViewHeight
        }
        
        if let _ = mutableTableCellState.genericFile {
            viewsHeight += FileInfoView.kThreadsListViewHeight
        }
        
        return textHeight + viewsHeight + kTopMargin + kBottomMargin
    }
    
    public static func getThreadRowHeightFor(
        _ tableCellState: MessageTableCellState,
        linkData: MessageTableCellState.LinkData? = nil,
        tribeData: MessageTableCellState.TribeData? = nil,
        botWebViewData: MessageTableCellState.BotWebViewData? = nil,
        collectionViewWidth: CGFloat
    ) -> CGFloat {
        ///No Bubble message views
        var mutableTableCellState = tableCellState
        let kGeneralMargin: CGFloat = 2.0
        
        let statusHeaderheight: CGFloat = getStatusHeaderHeightFor(tableCellState)
        
        var originalMessageTextHeight: CGFloat = 0
        var lastReplyTextHeight: CGFloat = 0
        var viewsHeight: CGFloat = 0.0
        
        if let threadState = mutableTableCellState.threadMessagesState {
            let originalMessage = threadState.originalMessage
            
            if let text = originalMessage.text, text.isNotEmpty {
                originalMessageTextHeight = getThreadOriginalTextMessageHeightFor(
                    text,
                    collectionViewWidth: collectionViewWidth,
                    maxHeight: Constants.kMessageLineHeight * 2
                )
            }
            
            if threadState.moreRepliesCount > 0 {
                viewsHeight += ThreadRepliesView.kViewHeightSeveralReplies
            } else if let _ = threadState.secondReplySenderInfo {
                viewsHeight += ThreadRepliesView.kViewHeight2Replies
            } else {
                viewsHeight += ThreadRepliesView.kViewHeight1Reply
            }
        }
        
        if let _ = mutableTableCellState.audio {
            viewsHeight += AudioMessageView.kViewHeight
        }
        
        if let _ = mutableTableCellState.messageMedia {
            viewsHeight += MediaMessageView.kThreadViewHeight
        }
        
        if let _ = mutableTableCellState.genericFile {
            viewsHeight += FileInfoView.kViewHeight
        }
        
        if let _ = mutableTableCellState.threadOriginalMessageAudio {
            viewsHeight += AudioMessageView.kViewHeight
        }
        
        if let _ = mutableTableCellState.threadOriginalMessageMedia {
            viewsHeight += MediaMessageView.kThreadViewHeight
        }
        
        if let _ = mutableTableCellState.threadOriginalMessageGenericFile {
            viewsHeight += FileInfoView.kViewHeight
        }
        
        if let text = mutableTableCellState.messageContent?.text, text.isNotEmpty {
            lastReplyTextHeight = getThreadOriginalTextMessageHeightFor(
                text,
                collectionViewWidth: collectionViewWidth,
                highlightedMatches: mutableTableCellState.messageContent?.highlightedMatches
            )
        }
        
        viewsHeight += ThreadLastMessageHeader.kViewHeight
        
        return originalMessageTextHeight + lastReplyTextHeight + (kGeneralMargin * 2) + statusHeaderheight + viewsHeight
        
    }
    
    public static func getRowHeightFor(
        _ tableCellState: MessageTableCellState,
        linkData: MessageTableCellState.LinkData? = nil,
        tribeData: MessageTableCellState.TribeData? = nil,
        botWebViewData: MessageTableCellState.BotWebViewData? = nil,
        collectionViewWidth: CGFloat
    ) -> CGFloat {
        var mutableTableCellState = tableCellState
        
        if mutableTableCellState.isThread {
            return ChatHelper.getThreadRowHeightFor(
                tableCellState,
                collectionViewWidth: collectionViewWidth
            )
        }
        
        ///No bubble message views
        if let _ = mutableTableCellState.dateSeparator {
            return DateSeparatorView.kViewHeight
        }
        
        if let _ = mutableTableCellState.deleted {
            return DeletedMessageView.kViewHeight
        }
        
        if let _ = mutableTableCellState.groupMemberNotification {
            return GroupActionMessageView.kViewHeight
        }
        
        if let _ = mutableTableCellState.groupMemberRequest {
            return GroupRequestView.kViewHeight
        }
        
        if let _ = mutableTableCellState.groupKickRemovedOrDeclined {
            return GroupRemovedView.kViewHeight
        }
        
        ///No Bubble message views
        let kGeneralMargin: CGFloat = 2.0
        
        let statusHeaderheight: CGFloat = getStatusHeaderHeightFor(tableCellState)
        
        let textHeight: CGFloat = getTextMessageHeightFor(
            tableCellState,
            linkData: linkData,
            tribeData: tribeData,
            collectionViewWidth: collectionViewWidth
        )
        
        let viewsHeight: CGFloat = getAdditionalViewsHeightFor(
            tableCellState,
            linkData: linkData,
            tribeData: tribeData,
            botWebViewData: botWebViewData
        )
        
        return textHeight + (kGeneralMargin * 2) + statusHeaderheight + viewsHeight
        
    }
    
    public static func getStatusHeaderHeightFor(
        _ tableCellState: MessageTableCellState
    ) -> CGFloat {
        var mutableTableCellState = tableCellState
        var statusHeaderheight: CGFloat = 25.0
        
        if let grouping = mutableTableCellState.bubble?.grouping, grouping.isGroupedAtTop() {
            statusHeaderheight = 0.0
        }
        
        return statusHeaderheight
    }
    
    public static func getTextMessageHeightFor(
        _ tableCellState: MessageTableCellState,
        linkData: MessageTableCellState.LinkData? = nil,
        tribeData: MessageTableCellState.TribeData? = nil,
        collectionViewWidth: CGFloat
    ) -> CGFloat {
        var mutableTableCellState = tableCellState
        var textHeight: CGFloat = 0.0
        
        var maxWidth = min(
            CommonNewMessageCollectionViewitem.kMaximumLabelBubbleWidth,
            collectionViewWidth - 80
        )
        
        if let _ = mutableTableCellState.directPayment {
            if let _ = mutableTableCellState.messageMedia {
                maxWidth = min(
                    CommonNewMessageCollectionViewitem.kMaximumDirectPaymentWithMediaBubbleWidth,
                    collectionViewWidth - 80
                )
            } else if let _ = mutableTableCellState.messageContent {
                maxWidth = min(
                    CommonNewMessageCollectionViewitem.kMaximumDirectPaymentWithTextBubbleWidth,
                    collectionViewWidth - 80
                )
            } else {
                maxWidth = min(
                    CommonNewMessageCollectionViewitem.kMaximumDirectPaymentBubbleWidth,
                    collectionViewWidth - 80
                )
            }
        } else if let _ = mutableTableCellState.messageMedia {
            maxWidth = min(
                CommonNewMessageCollectionViewitem.kMaximumMediaBubbleWidth,
                collectionViewWidth - 80
            )
        } else if let _ = mutableTableCellState.genericFile {
            maxWidth = min(
                CommonNewMessageCollectionViewitem.kMaximumFileBubbleWidth,
                collectionViewWidth - 80
            )
        } else if let _ = mutableTableCellState.audio {
            maxWidth = min(
                CommonNewMessageCollectionViewitem.kMaximumAudioBubbleWidth,
                collectionViewWidth - 80
            )
        } else if let _ = linkData {
            maxWidth = min(
                CommonNewMessageCollectionViewitem.kMaximumLinksBubbleWidth,
                collectionViewWidth - 80
            )
        } else if let _ = tribeData {
            maxWidth = min(
                CommonNewMessageCollectionViewitem.kMaximumLinksBubbleWidth,
                collectionViewWidth - 80
            )
        } else if let _ = mutableTableCellState.contactLink {
            maxWidth = min(
                CommonNewMessageCollectionViewitem.kMaximumLinksBubbleWidth,
                collectionViewWidth - 80
            )
        } else if let _ = mutableTableCellState.podcastComment {
            maxWidth = min(
                CommonNewMessageCollectionViewitem.kMaximumPodcastAudioBubbleWidth,
                collectionViewWidth - 80
            )
        } else if let _ = mutableTableCellState.messageContent, let _ = mutableTableCellState.paidContent {
            maxWidth = min(
                CommonNewMessageCollectionViewitem.kMaximumPaidTextViewBubbleWidth,
                collectionViewWidth - 80
            )
        }
        
        if let text = mutableTableCellState.messageContent?.text, text.isNotEmpty {
            
            textHeight = ChatHelper.getTextHeightFor(
                text: text,
                width: maxWidth,
                highlightedMatches: mutableTableCellState.messageContent?.highlightedMatches
            )
        }
        
        return textHeight
    }
    
    public static func getThreadOriginalTextMessageHeightFor(
        _ text: String?,
        collectionViewWidth: CGFloat,
        maxHeight: CGFloat? = nil,
        highlightedMatches: [NSTextCheckingResult]? = []
    ) -> CGFloat {
        var textHeight: CGFloat = 0.0
        
        let maxWidth = min(
            CommonNewMessageCollectionViewitem.kMaximumThreadBubbleWidth,
            collectionViewWidth - 80
        )
        
        if let text = text, text.isNotEmpty {
            textHeight = ChatHelper.getTextHeightFor(
                text: text,
                width: maxWidth,
                highlightedMatches: highlightedMatches
            )
        }
        
        if let maxHeight = maxHeight {
            return min(textHeight, maxHeight)
        }
        return textHeight
    }
    
    public static func getThreadListTextMessageHeightFor(
        _ text: String?,
        width: CGFloat,
        maxHeight: CGFloat,
        font: NSFont? = nil
    ) -> CGFloat {
        var textHeight: CGFloat = 0.0
        
        if let text = text, text.isNotEmpty {
            textHeight = ChatHelper.getTextHeightFor(
                text: text,
                width: width,
                font: font,
                labelMargins: 0
            )
        }
        
        return min(textHeight, maxHeight)
    }
    
    public static func getAdditionalViewsHeightFor(
        _ tableCellState: MessageTableCellState,
        linkData: MessageTableCellState.LinkData? = nil,
        tribeData: MessageTableCellState.TribeData? = nil,
        botWebViewData: MessageTableCellState.BotWebViewData? = nil
    ) -> CGFloat {
        
        var mutableTableCellState = tableCellState
        var viewsHeight: CGFloat = 0.0
        
        if let _ = mutableTableCellState.replyingMessage {
            viewsHeight += NewMessageReplyView.kViewHeight
        }
        
        if let _ = mutableTableCellState.directPayment {
            viewsHeight += DirectPaymentView.kViewHeight
        }
        
        if let invoice = mutableTableCellState.invoice {
            if mutableTableCellState.bubble?.direction == .Incoming && !invoice.isPaid {
                viewsHeight += InvoiceView.kViewIncomingHeight
            } else {
                viewsHeight += InvoiceView.kViewOutgoingHeight
            }
            
            if let memo = invoice.memo, memo.isNotEmpty {
                let textHeight = ChatHelper.getTextHeightFor(
                    text: memo,
                    width: CommonNewMessageCollectionViewitem.kMaximumPaidTextViewBubbleWidth
                ) - 16
                
                viewsHeight += textHeight
            }
        }
        
        if let _ = mutableTableCellState.payment {
            viewsHeight += InvoicePaymentView.kViewHeight
        }
        
        if let _ = mutableTableCellState.audio {
            viewsHeight += AudioMessageView.kViewHeight
        }
        
        if let _ = mutableTableCellState.podcastComment {
            viewsHeight += PodcastAudioView.kViewHeight
        }
        
        if let paidContent = mutableTableCellState.paidContent {
            if paidContent.shouldAddPadding {
                viewsHeight += SentPaidDetails.kViewHeight
            } else if mutableTableCellState.bubble?.direction.isIncoming() == true {
                viewsHeight += NewPaidAttachmentView.kViewHeight
            }
        }
        
        if let _ = mutableTableCellState.messageMedia {
            viewsHeight += MediaMessageView.kViewHeight
        }
        
        if let link = mutableTableCellState.callLink {
            if link.callMode == VideoCallHelper.CallMode.Audio {
                viewsHeight += JoinVideoCallView.kViewAudioOnlyHeight
            } else {
                viewsHeight += JoinVideoCallView.kViewHeight
            }
        }
        
        if let _ = mutableTableCellState.podcastBoost {
            viewsHeight += PodcastBoostView.kViewHeight
        }
        
        if let _ = mutableTableCellState.genericFile {
            viewsHeight += FileInfoView.kViewHeight
        }
        
        if let contactLink = mutableTableCellState.contactLink {
            if contactLink.isContact {
                viewsHeight += ContactLinkView.kViewHeightWithoutButton
            } else {
                viewsHeight += ContactLinkView.kViewHeightWithButton
            }
        }
        
        //        if let _ = mutableTableCellState.webLink {
        //            viewsHeight += NewLinkPreviewView.kViewHeight
        //        }
        
        if let tribeData = tribeData {
            if tribeData.showJoinButton {
                viewsHeight += TribeLinkView.kViewHeightWithButton
            } else {
                viewsHeight += TribeLinkView.kViewHeightWithoutButton
            }
        }
        
        if let _ = mutableTableCellState.boosts {
            viewsHeight += NewMessageBoostView.kViewHeight
        }
        
        if let botWebViewData = botWebViewData {
            viewsHeight += botWebViewData.height
        } else if let _ = mutableTableCellState.botHTMLContent {
            viewsHeight += BotResponseView.kViewHeight
        }
        
        return viewsHeight
    }
    
    public static func getTextHeightFor(
        text: String,
        width: CGFloat,
        font: NSFont? = nil,
        highlightedMatches: [NSTextCheckingResult]? = [],
        labelMargins: CGFloat? = nil
    ) -> CGFloat {
        let attrs = [NSAttributedString.Key.font: font ?? Constants.kMessageFont]
        let attributedString = NSMutableAttributedString(string: text, attributes: attrs)
        
        for (index, match) in (highlightedMatches ?? []).enumerated() {
            
            ///Subtracting the previous matches delimiter characters since they have been removed from the string
            ///Subtracting the \` characters from the length since removing the chars caused the range to be 2 less chars
            let substractionNeeded = index * 2
            let adaptedRange = NSRange(location: match.range.location - substractionNeeded, length: match.range.length - 2)
            
            attributedString.addAttributes(
                [
                    NSAttributedString.Key.font: Constants.kMessageHighlightedFont,
                    NSAttributedString.Key.backgroundColor: NSColor.Sphinx.HighlightedTextBackground
                ],
                range: adaptedRange
            )
            
        }
        
        let kLabelHorizontalMargins: CGFloat = 32.0
        let kLabelVerticalMargins: CGFloat = labelMargins ?? 32.0
        
        let textHeight = attributedString.boundingRect(
            with: NSSize(width: width - kLabelHorizontalMargins, height: CGFLOAT_MAX),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        ).height + kLabelVerticalMargins
        
        return textHeight
    }
}
