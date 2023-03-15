//
//  ChatHelper.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 18/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class ChatHelper {
    var myView : NSView? = nil
    
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
    
    func registerCellsForChat(collectionView: NSCollectionView) {
        collectionView.registerItem(MessageSentCollectionViewItem.self)
        collectionView.registerItem(MessageReceivedCollectionViewItem.self)
        collectionView.registerItem(PaymentReceivedCollectionViewItem.self)
        collectionView.registerItem(PaymentSentCollectionViewItem.self)
        collectionView.registerItem(InvoiceSentCollectionViewItem.self)
        collectionView.registerItem(InvoiceReceivedCollectionViewItem.self)
        collectionView.registerItem(ExpiredInvoiceSentCollectionViewItem.self)
        collectionView.registerItem(ExpiredInvoiceReceivedCollectionViewItem.self)
        collectionView.registerItem(PaidInvoiceSentCollectionViewItem.self)
        collectionView.registerItem(PaidInvoiceReceivedCollectionViewItem.self)
        collectionView.registerItem(DayHeaderCollectionViewItem.self)
        collectionView.registerItem(DirectPaymentSentCollectionViewItem.self)
        collectionView.registerItem(DirectPaymentReceivedCollectionViewItem.self)
        collectionView.registerItem(PictureSentCollectionViewItem.self)
        collectionView.registerItem(PictureReceivedCollectionViewItem.self)
        collectionView.registerItem(VideoSentCollectionViewItem.self)
        collectionView.registerItem(VideoReceivedCollectionViewItem.self)
        collectionView.registerItem(AudioSentCollectionViewItem.self)
        collectionView.registerItem(AudioReceivedCollectionViewItem.self)
        collectionView.registerItem(GroupActionMessageCollectionViewItem.self)
        collectionView.registerItem(GroupRemovedCollectionViewItem.self)
        collectionView.registerItem(GroupRequestCollectionViewItem.self)
        collectionView.registerItem(LoadingMoreCollectionViewItem.self)
        collectionView.registerItem(VideoCallSentCollectionViewItem.self)
        collectionView.registerItem(VideoCallReceivedCollectionViewItem.self)
        collectionView.registerItem(PaidMessageSentCollectionViewItem.self)
        collectionView.registerItem(PaidMessageReceivedCollectionViewItem.self)
        collectionView.registerItem(DeletedMessageSentCollectionViewItem.self)
        collectionView.registerItem(DeletedMessageReceivedCollectionViewItem.self)
        collectionView.registerItem(MessageWebViewReceivedCollectionViewItem.self)
        collectionView.registerItem(FileSentCollectionViewItem.self)
        collectionView.registerItem(FileReceivedCollectionViewItem.self)
        collectionView.registerItem(PodcastCommentReceivedCollectionViewItem.self)
        collectionView.registerItem(PodcastCommentSentCollectionViewItem.self)
        collectionView.registerItem(PodcastBoostReceivedCollectionViewItem.self)
        collectionView.registerItem(PodcastBoostSentCollectionViewItem.self)
    }
    
    func getItemFor(messageRow: TransactionMessageRow, indexPath: IndexPath, on collectionView: NSCollectionView) -> NSCollectionViewItem {
        let isCallLink = messageRow.isCallLink
        let isGiphy = messageRow.isGiphy
        
        var cell: NSCollectionViewItem! = nil
        
        guard let type = messageRow.getType() else {
            if let _ = messageRow.headerDate {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DayHeaderCollectionViewItem"), for: indexPath)
                return cell
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LoadingMoreCollectionViewItem"), for: indexPath)
                return cell
            }
        }
        
        guard let message = messageRow.transactionMessage else {
            return cell
        }
        
        let incoming = messageRow.isIncoming()
        
        let messageStatus = TransactionMessage.TransactionMessageStatus(fromRawValue: Int(message.status))
        if messageStatus == TransactionMessage.TransactionMessageStatus.deleted {
            if incoming {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DeletedMessageReceivedCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DeletedMessageSentCollectionViewItem"), for: indexPath)
            }
            return cell
        }
        
        let messageType = TransactionMessage.TransactionMessageType(fromRawValue: Int(type))
        switch (messageType) {
        case TransactionMessage.TransactionMessageType.message:
            let isPodcastComment = messageRow.isPodcastComment
            let isPodcastBoost = messageRow.isPodcastBoost
            
            if incoming {
                if isCallLink {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "VideoCallReceivedCollectionViewItem"), for: indexPath)
                } else if isGiphy {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PictureReceivedCollectionViewItem"), for: indexPath)
                } else if isPodcastComment {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastCommentReceivedCollectionViewItem"), for: indexPath)
                } else if isPodcastBoost {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastBoostReceivedCollectionViewItem"), for: indexPath)
                }else if messageRow.hasCodeSnippet(){
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageReceivedWithCodeCollectionViewItem"), for: indexPath)
                }
                else {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageReceivedCollectionViewItem"), for: indexPath)
                }
            } else {
                if isCallLink {
                     cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "VideoCallSentCollectionViewItem"), for: indexPath)
                } else if isGiphy {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PictureSentCollectionViewItem"), for: indexPath)
                } else if isPodcastComment {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastCommentSentCollectionViewItem"), for: indexPath)
                } else if isPodcastBoost {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastBoostSentCollectionViewItem"), for: indexPath)
                }
                else if messageRow.hasCodeSnippet(){
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageSentWithCodeCollectionViewItem"), for: indexPath)
                }
                else {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageSentCollectionViewItem"), for: indexPath)
                }
            }
            break
        case TransactionMessage.TransactionMessageType.boost:
            if incoming {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastBoostReceivedCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PodcastBoostSentCollectionViewItem"), for: indexPath)
            }
        case TransactionMessage.TransactionMessageType.invoice:
            if incoming {
                if message.isPaid() {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PaidInvoiceReceivedCollectionViewItem"), for: indexPath)
                } else if message.isExpired() {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ExpiredInvoiceReceivedCollectionViewItem"), for: indexPath)
                } else {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "InvoiceReceivedCollectionViewItem"), for: indexPath)
                }
            } else {
                if message.isPaid() {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PaidInvoiceSentCollectionViewItem"), for: indexPath)
                } else if message.isExpired() {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ExpiredInvoiceSentCollectionViewItem"), for: indexPath)
                } else {
                    cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "InvoiceSentCollectionViewItem"), for: indexPath)
                }
            }
            break
        case TransactionMessage.TransactionMessageType.payment:
            if incoming {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PaymentReceivedCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PaymentSentCollectionViewItem"), for: indexPath)
            }
            break
        case TransactionMessage.TransactionMessageType.confirmation:
            break
        case TransactionMessage.TransactionMessageType.cancellation:
            break
        case TransactionMessage.TransactionMessageType.directPayment:
            if incoming {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DirectPaymentReceivedCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DirectPaymentSentCollectionViewItem"), for: indexPath)
            }
            break
        case TransactionMessage.TransactionMessageType.imageAttachment, TransactionMessage.TransactionMessageType.pdfAttachment:
            if incoming {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PictureReceivedCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PictureSentCollectionViewItem"), for: indexPath)
            }
            break
        case TransactionMessage.TransactionMessageType.videoAttachment:
            if incoming {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "VideoReceivedCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "VideoSentCollectionViewItem"), for: indexPath)
            }
            break
        case TransactionMessage.TransactionMessageType.audioAttachment:
            if incoming {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AudioReceivedCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AudioSentCollectionViewItem"), for: indexPath)
            }
            break
        case TransactionMessage.TransactionMessageType.textAttachment:
            if incoming {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PaidMessageReceivedCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PaidMessageSentCollectionViewItem"), for: indexPath)
            }
            break
        case TransactionMessage.TransactionMessageType.fileAttachment:
            if incoming {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileReceivedCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileSentCollectionViewItem"), for: indexPath)
            }
            break
        case TransactionMessage.TransactionMessageType.groupLeave, TransactionMessage.TransactionMessageType.groupJoin:
            cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupActionMessageCollectionViewItem"), for: indexPath)
            break
        case TransactionMessage.TransactionMessageType.groupKick, TransactionMessage.TransactionMessageType.groupDelete:
            cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupRemovedCollectionViewItem"), for: indexPath)
            break
        case TransactionMessage.TransactionMessageType.memberApprove:
            if message.chat?.isMyPublicGroup() ?? false {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupRequestCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupActionMessageCollectionViewItem"), for: indexPath)
            }
            break
        case TransactionMessage.TransactionMessageType.memberReject:
            if message.chat?.isMyPublicGroup() ?? false {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupRequestCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupRemovedCollectionViewItem"), for: indexPath)
            }
            break
        case TransactionMessage.TransactionMessageType.memberRequest:
            cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupRequestCollectionViewItem"), for: indexPath)
            break
        case TransactionMessage.TransactionMessageType.botResponse:
            if (message.messageContent?.isValidHTML ?? true) {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageWebViewReceivedCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageReceivedCollectionViewItem"), for: indexPath)
            }
            break
        case TransactionMessage.TransactionMessageType.call:
            if incoming {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "VideoCallReceivedCollectionViewItem"), for: indexPath)
            } else {
                cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "VideoCallSentCollectionViewItem"), for: indexPath)
            }
            break
        default:
            break
        }
        
        if cell == nil {
            cell = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "EmptyChatCollectionViewItem"), for: indexPath)
        }
        return cell
    }
    
    func getRowHeight(incoming: Bool, messageRow: TransactionMessageRow, chatWidth: CGFloat) -> CGFloat {
        var  height: CGFloat = 0.0
        let isCallLink = messageRow.isCallLink
        let isGiphy = messageRow.isGiphy
        
        guard let message = messageRow.transactionMessage else {
            return height
        }
        
        guard let type = messageRow.getType() else {
            return height
        }
        
        let status = TransactionMessage.TransactionMessageStatus(fromRawValue: Int(message.status))
        if status == TransactionMessage.TransactionMessageStatus.deleted {
            return CommonDeletedMessageCollectionViewItem.getRowHeight()
        }
        
        let messageType = TransactionMessage.TransactionMessageType(fromRawValue: Int(type))
        switch (messageType) {
        case TransactionMessage.TransactionMessageType.message,
             TransactionMessage.TransactionMessageType.boost:
            let isPodcastComment = messageRow.isPodcastComment
            let isPodcastBoost = messageRow.isPodcastBoost
            
            if isCallLink {
                height = CommonVideoCallCollectionViewItem.getRowHeight(messageRow: messageRow)
            } else if isGiphy {
                height = CommonPictureCollectionViewItem.getRowHeight(messageRow: messageRow)
            } else if isPodcastComment {
                height = CommonPodcastCommentCollectionViewItem.getRowHeight(messageRow: messageRow)
            } else if isPodcastBoost {
                height = CommonPodcastBoostCollectionViewItem.getRowHeight()
            } else {
                if incoming {
                    if messageRow.hasCodeSnippet(){
                        height = MessageReceivedWithCodeCollectionViewItem.getRowHeight(messageRow: messageRow)
                    }
                    else{
                        height = MessageReceivedCollectionViewItem.getRowHeight(messageRow: messageRow)
                    }
                } else {
                    if messageRow.hasCodeSnippet(){
                        height = MessageSentWithCodeCollectionViewItem.getRowHeight(messageRow: messageRow)
                    }
                    else{
                        height = MessageSentCollectionViewItem.getRowHeight(messageRow: messageRow)
                    }
                }
            }
            break
        case TransactionMessage.TransactionMessageType.invoice:
            if incoming {
                if messageRow.transactionMessage.isPaid() {
                    height = PaidInvoiceReceivedCollectionViewItem.getRowHeight(messageRow: messageRow)
                } else if messageRow.transactionMessage.isExpired() {
                    height = CommonExpiredInvoiceCollectionViewItem.getRowHeight()
                } else {
                    height = InvoiceReceivedCollectionViewItem.getRowHeight(messageRow: messageRow)
                }
            } else {
                if messageRow.transactionMessage.isPaid() {
                    height = PaidInvoiceSentCollectionViewItem.getRowHeight(messageRow: messageRow)
                } else if messageRow.transactionMessage.isExpired() {
                    height = CommonExpiredInvoiceCollectionViewItem.getRowHeight()
                } else {
                    height = InvoiceSentCollectionViewItem.getRowHeight(messageRow: messageRow)
                }
            }
            break
        case TransactionMessage.TransactionMessageType.payment:
            height = CommonPaymentCollectionViewItem.getRowHeight()
            break
        case TransactionMessage.TransactionMessageType.confirmation:
            break
        case TransactionMessage.TransactionMessageType.cancellation:
            break
        case TransactionMessage.TransactionMessageType.directPayment:
            height = CommonDirectPaymentCollectionViewItem.getRowHeight(messageRow: messageRow)
            break
        case TransactionMessage.TransactionMessageType.imageAttachment, TransactionMessage.TransactionMessageType.pdfAttachment:
            height = CommonPictureCollectionViewItem.getRowHeight(messageRow: messageRow)
            break
        case TransactionMessage.TransactionMessageType.videoAttachment:
            height = CommonVideoCollectionViewItem.getRowHeight(messageRow: messageRow)
            break
        case TransactionMessage.TransactionMessageType.audioAttachment:
            height = CommonAudioCollectionViewItem.getRowHeight(messageRow: messageRow)
            break
        case TransactionMessage.TransactionMessageType.textAttachment:
            if incoming {
                height = PaidMessageReceivedCollectionViewItem.getRowHeight(messageRow: messageRow, chatWidth: chatWidth)
            } else {
                height = PaidMessageSentCollectionViewItem.getRowHeight(messageRow: messageRow, chatWidth: chatWidth)
            }
            break
        case TransactionMessage.TransactionMessageType.fileAttachment:
            height = CommonFileCollectionViewItem.getRowHeight(messageRow: messageRow)
            break
        case TransactionMessage.TransactionMessageType.groupLeave, TransactionMessage.TransactionMessageType.groupJoin:
            height = GroupActionMessageCollectionViewItem.getRowHeight()
            break
        case TransactionMessage.TransactionMessageType.groupKick, TransactionMessage.TransactionMessageType.groupDelete:
            height = GroupRemovedCollectionViewItem.getRowHeight()
        case TransactionMessage.TransactionMessageType.memberApprove:
            if message.chat?.isMyPublicGroup() ?? false {
                 height = GroupRequestCollectionViewItem.getRowHeight()
            } else {
                height = GroupActionMessageCollectionViewItem.getRowHeight()
            }
            break
        case TransactionMessage.TransactionMessageType.memberReject:
            if message.chat?.isMyPublicGroup() ?? false {
                 height = GroupRequestCollectionViewItem.getRowHeight()
            } else {
                height = GroupRemovedCollectionViewItem.getRowHeight()
            }
            break
        case TransactionMessage.TransactionMessageType.memberRequest:
            height = GroupRequestCollectionViewItem.getRowHeight()
            break
        case TransactionMessage.TransactionMessageType.botResponse:
            if (message.messageContent?.isValidHTML ?? true) {
                height = MessageWebViewReceivedCollectionViewItem.getRowHeight(messageRow: messageRow)
            } else {
                height = MessageReceivedCollectionViewItem.getRowHeight(messageRow: messageRow)
            }
            break
        case TransactionMessage.TransactionMessageType.call:
            height = CommonVideoCallCollectionViewItem.getRowHeight(messageRow: messageRow)
            break
        default:
            break
        }
        
        let heightToSubstract = getHeightToSubstract(message: messageRow.transactionMessage)
        if height > 0 && heightToSubstract > 0 {
            return height - heightToSubstract
        }
        return height
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
    
    func processGroupedMessagesOnDelete(rowToDelete: TransactionMessageRow, previousRow: TransactionMessageRow?, nextRow: TransactionMessageRow?) -> (Bool, Bool) {
        let consecutiveMessages = rowToDelete.transactionMessage.consecutiveMessages
        if let nextRow = nextRow, !nextRow.isDayHeader && !consecutiveMessages.previousMessage && consecutiveMessages.nextMessage {
            nextRow.transactionMessage.consecutiveMessages.previousMessage = false
            return (false, true)
        }
        if let previousRow = previousRow, !previousRow.isDayHeader && consecutiveMessages.previousMessage && !consecutiveMessages.nextMessage {
            previousRow.transactionMessage.consecutiveMessages.nextMessage = false
            return (true, false)
        }
        return (false, false)
    }
    
    func processGroupedMessagesOnUpdate(updatedMessageRow: TransactionMessageRow, previousRow: TransactionMessageRow?, nextRow: TransactionMessageRow?) {
        var consecutiveMessages = updatedMessageRow.transactionMessage.consecutiveMessages
        consecutiveMessages.previousMessage = false
        consecutiveMessages.nextMessage = false
        
        if let nextRow = nextRow, !nextRow.isDayHeader {
            nextRow.transactionMessage.consecutiveMessages.previousMessage = false
        }
        if let previousRow = previousRow, !previousRow.isDayHeader {
            previousRow.transactionMessage.consecutiveMessages.nextMessage = false
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
        if let replyUUID = message.replyUUID {
            let outgoing = message.isOutgoing()
            let senderImageUrl: String? = message.getMessageSenderImageUrl(owner: owner, contact: contact)
            
            let user: (String, NSColor, String?) = (message.getMessageSenderNickname(forceNickname: true), ChatHelper.getSenderColorFor(message: message), senderImageUrl)
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
}
