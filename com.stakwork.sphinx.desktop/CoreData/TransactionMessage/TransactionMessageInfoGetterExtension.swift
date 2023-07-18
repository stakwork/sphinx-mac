//
//  TransactionMessageInfoGetterExtension.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

extension TransactionMessage {
    
    var messageDate: Date {
        get {
            return self.date ?? Date()
        }
    }
    
    public enum MessageActionsItem: Int {
        case Delete
        case Copy
        case CopyLink
        case CopyPubKey
        case CopyCallLink
        case Reply
        case Save
        case Boost
        case Resend
        case Pin
        case Unpin
    }
    
    //Sender and Receiver info
    func getMessageSender() -> UserContact? {
        return UserContact.getContactWith(id: self.senderId)
    }
    
    func getMessageReceiver() -> UserContact? {
        if let chat = self.chat, chat.type == Chat.ChatType.conversation.rawValue {
            for user in chat.getContacts() {
                if user.id != self.senderId {
                    return user
                }
            }
        }
        return nil
    }
    
    func getMessageReceiverNickname() -> String {
        if let receiver = getMessageReceiver() {
            return receiver.getName()
        }
        return "name.unknown".localized
    }
    
    func getMessageSenderNickname(
        minimized: Bool = false,
        forceNickname: Bool = false,
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        var alias = "name.unknown".localized
        
        if let senderAlias = senderAlias {
            alias = senderAlias
        } else {
            if isIncoming(ownerId: owner.id) {
                if let sender = (contact ?? getMessageSender()) {
                    alias = sender.getUserName(forceNickname: forceNickname)
                }
            } else {
                alias = owner.getUserName(forceNickname: forceNickname)
            }
        }
        
        if let first = alias.components(separatedBy: " ").first, minimized {
            return first
        }
        
        return alias
    }
    
    func getMessageSenderImageUrl(
        owner: UserContact?,
        contact: UserContact?
    ) -> String? {
        let outgoing = self.isOutgoing()
        
        if (outgoing) {
            return self.chat?.myPhotoUrl ?? owner?.getPhotoUrl()
        } else {
            return self.senderPic ?? contact?.getPhotoUrl()
        }
    }
    
    func hasSameSenderThan(message: TransactionMessage?) -> Bool {
        let hasSameSenderId = senderId == (message?.senderId ?? -1)
        let hasSameSenderAlias = (senderAlias ?? "") == (message?.senderAlias ?? "")
        let hasSamePicture = (senderPic ?? "") == (message?.senderPic ?? "")
        
        return hasSameSenderId && hasSameSenderAlias && hasSamePicture
    }
    
    func getMessageSenderProfilePic(chat: Chat?, contact: UserContact?) -> String? {
        var image: String? = contact?.avatarUrl?.removeDuplicatedProtocol().trim()
        
        if chat?.isPublicGroup() ?? false {
            image = self.senderPic?.removeDuplicatedProtocol().trim()
        }
        
        if let image = image, !image.isEmpty {
            return image
        }
        return nil
    }

    
    //Message content and encryption
    static func isContentEncrypted(messageEncrypted: Bool, type: Int, mediaKey: String?) -> Bool {
        if type == TransactionMessageType.attachment.rawValue {
            return mediaKey != nil && mediaKey != ""
        }
        return messageEncrypted
    }
    
    func canBeDecrypted() -> Bool {
        if let messageC = self.messageContent, messageC.isEncryptedString() {
            return false
        }
        
        return true
    }
    
    func hasMessageContent() -> Bool {
        let messageC = (messageContent ?? "")
        
        if isGiphy() {
            if let message = GiphyHelper.getMessageFrom(message: messageC) {
                return !message.isEmpty
            }
        }
        
        if isPodcastComment() {
            return self.getPodcastComment()?.text != nil
        }

        return messageC != ""
    }
    
    func getMessageDescription() -> String {
        var adjustedMC = self.messageContent ?? ""
        
        if isGiphy(), let message = GiphyHelper.getMessageFrom(message: adjustedMC) {
            return message
        }
        
        if isPodcastComment(), let podcastComment = self.getPodcastComment() {
            return podcastComment.text ?? ""
        }
        
        if isPodcastBoost() {
            return "Boost"
        }
        
        if isCallLink() {
            adjustedMC = "join.call".localized
        }
        
        return adjustedMC
    }
    
    func getReplyMessageContent() -> String {
        if hasMessageContent() {
            let messageContent = bubbleMessageContentString ?? ""
            return messageContent.isValidHTML ? "bot.response.preview".localized : messageContent
        }
        if let fileName = self.mediaFileName {
            return fileName
        }
        return ""
    }
    
    func getDecrytedMessage() -> String {
        if let messageC = self.messageContent {
            if messageC.isEncryptedString() {
                let (decrypted, message) = EncryptionManager.sharedInstance.decryptMessage(message: messageC)
                if decrypted {
                    self.messageContent = message
                    return message
                }
            }
        }
        return "encryption.error".localized.uppercased()
    }
    
    func getPaidMessageContent() -> String {
        var adjustedMC = self.messageContent ?? ""
        
        if self.isPendingPaidMessage() {
            if paidMessageError {
                adjustedMC = "cannot.load.message.data".localized.uppercased()
            } else {
                adjustedMC = "pay.to.unlock.msg".localized.uppercased()
            }
        } else if self.isLoadingPaidMessage() {
            adjustedMC = "loading.paid.message".localized.uppercased()
        }
        
        return adjustedMC
    }
    
    //Direction
    func getDirection(id: Int) -> TransactionMessageDirection {
        if Int(self.senderId) == id {
            return TransactionMessageDirection.outgoing
        } else {
            return TransactionMessageDirection.incoming
        }
    }
    
    func isIncoming(
        ownerId: Int? = nil
    ) -> Bool {
        return getDirection(id: ownerId ?? UserData.sharedInstance.getUserId()) == TransactionMessageDirection.incoming
    }
    
    func isOutgoing(
        ownerId: Int? = nil
    ) -> Bool {
        return getDirection(id: ownerId ?? UserData.sharedInstance.getUserId()) == TransactionMessageDirection.outgoing
    }
    
    func isSeen(
        ownerId: Int
    ) -> Bool {
        return self.isOutgoing(ownerId: ownerId) || self.seen
    }
    
    //Statues
    func isFailedOrMediaExpired() -> Bool {
        let failed = self.failed()
        let expired = self.isMediaExpired()
        
        return failed || expired
    }
    
    func received() -> Bool {
        return status == TransactionMessageStatus.received.rawValue
    }
    
    func failed() -> Bool {
        return status == TransactionMessageStatus.cancelled.rawValue || status == TransactionMessageStatus.failed.rawValue
    }
    
    func isPaid() -> Bool {
        return status == TransactionMessageStatus.confirmed.rawValue
    }
    
    func isExpired() -> Bool {
        let expired = Date().timeIntervalSince1970 > (self.expirationDate ?? Date()).timeIntervalSince1970
        return expired
    }
    
    func isCancelled() -> Bool {
        return status == TransactionMessageStatus.cancelled.rawValue
    }
    
    public func isConfirmedAsReceived() -> Bool {
        return self.status == TransactionMessageStatus.received.rawValue
    }
    
    //Message type
    func getType() -> Int? {
        if let mediaType = getMediaType() {
            return mediaType
        }
        return self.type
    }
    
    func isMediaAttachment() -> Bool {
        return (isAttachment() && getType() != TransactionMessageType.textAttachment.rawValue) || isGiphy()
    }
    
    func isPaidMessage() -> Bool {
        return isAttachment() && getType() == TransactionMessageType.textAttachment.rawValue
    }
    
    func isPendingPaidMessage() -> Bool {
        return isPaidMessage() && isIncoming() && getMediaUrl(queryDB: false) == nil && (messageContent?.isEmpty ?? true)
    }
    
    func isLoadingPaidMessage() -> Bool {
        if let _ = getMediaUrl(), (messageContent?.isEmpty ?? true) && isPaidMessage() {
            return true
        }
        return false
    }
    
    func isMessageUploadingAttachment() -> Bool {
        return isAttachment() && getType() == TransactionMessageType.textAttachment.rawValue && messageContent == nil && !isIncoming()
    }
    
    func isTextMessage() -> Bool {
        return getType() == TransactionMessageType.message.rawValue
    }
    
    func isAttachment() -> Bool {
        return type == TransactionMessageType.attachment.rawValue
    }
    
    func isBotResponse() -> Bool {
        return type == TransactionMessageType.botResponse.rawValue
    }
    
    func isVideo() -> Bool {
        return getMediaType() == TransactionMessage.TransactionMessageType.videoAttachment.rawValue
    }
    
    func isAudio() -> Bool {
        return getMediaType() == TransactionMessage.TransactionMessageType.audioAttachment.rawValue
    }
    
    func isPDF() -> Bool {
        return getMediaType() == TransactionMessage.TransactionMessageType.pdfAttachment.rawValue
    }
    
    func isFileAttachment() -> Bool {
        return getMediaType() == TransactionMessage.TransactionMessageType.fileAttachment.rawValue
    }
    
    func isPicture() -> Bool {
        return isAttachment() && (mediaType?.contains("image") ?? false)
    }
    
    func isGif() -> Bool {
        return isAttachment() && (mediaType?.contains("gif") ?? false)
    }
    
    func isGiphy() -> Bool {
        return (self.messageContent ?? "").isGiphy
    }
    
    func isPodcastComment() -> Bool {
        return (self.messageContent ?? "").isPodcastComment
    }
    
    func isPodcastBoost() -> Bool {
        return (self.messageContent ?? "").isPodcastBoost ||
               (type == TransactionMessageType.boost.rawValue && replyUUID == nil)
    }
    
    func isPayment() -> Bool {
        return type == TransactionMessageType.payment.rawValue
    }
    
    func isUnknownType() -> Bool {
        return type == TransactionMessageType.unknown.rawValue
    }
    
    func isInvoice() -> Bool {
        return type == TransactionMessageType.invoice.rawValue
    }
    
    func isBoosted() -> Bool {
        return self.reactions != nil && (self.reactions?.totalSats ?? 0) > 0
    }
    
    func isMessageReaction() -> Bool {
        return type == TransactionMessageType.boost.rawValue && (!(replyUUID ?? "").isEmpty || (messageContent?.isEmpty ?? true))
    }
    
    func isApprovedRequest() -> Bool {
        return type == TransactionMessageType.memberApprove.rawValue
    }
    
    func isDeclinedRequest() -> Bool {
        return type == TransactionMessageType.memberReject.rawValue
    }
    
    func isGroupActionMessage() -> Bool {
        return type == TransactionMessageType.groupJoin.rawValue ||
               type == TransactionMessageType.groupLeave.rawValue ||
               type == TransactionMessageType.groupKick.rawValue ||
               type == TransactionMessageType.memberRequest.rawValue ||
               type == TransactionMessageType.memberApprove.rawValue ||
               type == TransactionMessageType.memberReject.rawValue
    }
    
    func isDeleted() -> Bool {
        return status == TransactionMessageStatus.deleted.rawValue
    }
    
    func isNotConsecutiveMessage() -> Bool {
        return isPayment() || isInvoice() || isGroupActionMessage() || isDeleted()
    }
    
    func isDirectPayment() -> Bool {
        return type == TransactionMessageType.directPayment.rawValue
    }
    
    func isCallLink() -> Bool {
        return type == TransactionMessageType.call.rawValue || messageContent?.isCallLink == true
    }
    
    func canBeDeleted() -> Bool {
        return isOutgoing() || (self.chat?.isMyPublicGroup() ?? false)
    }
    
    func isReply() -> Bool {
        if let replyUUID = replyUUID, !replyUUID.isEmpty {
            return true
        }
        return false
    }
    
    var isPinActionAllowed: Bool {
        get {
            return (self.chat?.isMyPublicGroup() ?? false) && !isMessagePinned
        }
    }
    
    var isUnpinActionAllowed: Bool {
        get {
            return (self.chat?.isMyPublicGroup() ?? false) && isMessagePinned
        }
    }
    
    var isMessagePinned: Bool {
        get {
            return self.uuid == self.chat?.pinnedMessageUUID
        }
    }
    
    var bubbleMessageContentString: String? {
        get {
            if isGiphy(), let message = GiphyHelper.getMessageFrom(message: messageContent ?? "") {
                return message
            }
            
            if isPodcastComment(), let podcastComment = self.getPodcastComment() {
                return podcastComment.text
            }
            
            if isPodcastBoost() {
                return nil
            }
            
            if isCallLink() {
                return nil
            }
            
            if let messageC = messageContent {
                if messageC.isEncryptedString() {
                    return "encryption.error".localized
                }
            }
            
            return self.messageContent
        }
    }
    
    func getReplyingTo() -> TransactionMessage? {
        if let replyUUID = replyUUID, !replyUUID.isEmpty {
            if let replyingMessage = replyingMessage {
                return replyingMessage
            }
            replyingMessage = TransactionMessage.getMessageWith(uuid: replyUUID)
            return replyingMessage
        }
        return nil
    }
    
    func getAmountString() -> String {
        let result = self.amount ?? NSDecimalNumber(value: 0)
        let amountString = Int(truncating: result).formattedWithSeparator
        return amountString
    }
    
    func getInvoicePaidAmountString() -> String {
        let invoice = TransactionMessage.getInvoiceWith(paymentHash: self.paymentHash ?? "")
        return invoice?.getAmountString() ?? "0"
    }
    
    func getActionsMenuOptions() -> [(tag: Int, icon: String?, iconImage: String?, label: String)] {
        var options = [(tag: Int, icon: String?, iconImage: String?, label: String)]()
        
        if let messageContent = messageContent, messageContent != "" && !isGiphy() {
            if !self.isCallLink() && !messageContent.isEncryptedString() {
                options.append((MessageActionsItem.Copy.rawValue, "", nil, "copy.text".localized))
            }
            
            if !self.isCallLink() && messageContent.stringLinks.count > 0 {
                options.append((MessageActionsItem.CopyLink.rawValue, "link", nil, "copy.link".localized))
            }
            
            if messageContent.pubKeyMatches.count > 0 {
                options.append((MessageActionsItem.CopyPubKey.rawValue, "supervisor_account", nil, "copy.pub.key".localized))
            }
            
            if self.isCallLink() {
                options.append((MessageActionsItem.CopyCallLink.rawValue, "link", nil, "copy.call.link".localized))
            }
            
            if isPinActionAllowed {
                options.append(
                    (MessageActionsItem.Pin.rawValue, "push_pin", nil, "pin.message".localized)
                )
            }
            
            if isUnpinActionAllowed {
                options.append(
                    (MessageActionsItem.Unpin.rawValue, "push_pin", nil, "unpin.message".localized)
                )
            }
        }
        
        if (isTextMessage() || isAttachment() || isBotResponse()) && !(uuid ?? "").isEmpty {
            options.append((MessageActionsItem.Reply.rawValue, "", nil, "reply".localized))
        }
        
        if canBeDownloaded() {
            options.append((MessageActionsItem.Save.rawValue, "", nil, "save.file".localized))
        }
        
        if (!isInvoice() || (isInvoice() && !isPaid())) && canBeDeleted() {
            options.append((MessageActionsItem.Delete.rawValue, "delete", nil, "delete.message".localized))
        }
        
        if shouldAllowBoost() {
            options.append((MessageActionsItem.Boost.rawValue, nil, "boostIconGreen", "Boost"))
        }
        
        if failed() && isTextMessage() {
            options.append((MessageActionsItem.Resend.rawValue, "send", nil, "resend.message".localized))
        }
        
        return options
    }
    
    func shouldAllowBoost() -> Bool {
        return isIncoming() &&
        !isInvoice() &&
        !isDirectPayment() &&
        !isCallLink() &&
        !(uuid ?? "").isEmpty
    }
    
    func isNewUnseenMessage() -> Bool {
        let chatSeen = (self.chat?.seen ?? false)
        var newMessage = !chatSeen && !seen && !failed() && isIncoming()
        
        let (purchaseStateItem, seen) = getPurchaseStateItem()
        if let _ = purchaseStateItem {
            newMessage = !seen
        }
        
        return newMessage
    }
    
    func isUniqueOnChat() -> Bool {
        return (self.chat?.messages?.count ?? 0) == 1
    }
    
    func save(webViewHeight height: CGFloat) {
        if var heighs: [Int: CGFloat] = UserDefaults.Keys.webViewsHeight.getObject() {
            heighs[self.id] = height
            UserDefaults.Keys.webViewsHeight.setObject(heighs)
        } else {
            UserDefaults.Keys.webViewsHeight.setObject([self.id: height])
        }
    }
    
    func getWebViewHeight() -> CGFloat? {
        if let heighs: [Int: CGFloat] = UserDefaults.Keys.webViewsHeight.getObject() {
            return heighs[self.id]
        }
        return nil
    }
    
    //Message description
    func getMessageContentPreview(
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        let amount = self.amount ?? NSDecimalNumber(value: 0)
        let amountString = Int(truncating: amount).formattedWithSeparator
        
        let incoming = self.isIncoming(ownerId: owner.id)
        let directionString = incoming ? "received".localized : "sent".localized
        let senderAlias = self.getMessageSenderNickname(minimized: true, owner: owner, contact: contact)
        
        if isDeleted() {
            return "message.x.deleted".localized
        }

        switch (self.getType()) {
        case TransactionMessage.TransactionMessageType.message.rawValue,
             TransactionMessage.TransactionMessageType.call.rawValue:
            if self.isGiphy() {
                return "\("gif.capitalize".localized) \(directionString)"
            } else {
                return "\(senderAlias): \(self.getMessageDescription())"
            }
        case TransactionMessage.TransactionMessageType.invoice.rawValue:
            return  "\("invoice".localized) \(directionString): \(amountString) sats"
        case TransactionMessage.TransactionMessageType.payment.rawValue:
            let invoiceAmount = getInvoicePaidAmountString()
            return  "\("payment".localized) \(directionString): \(invoiceAmount) sats"
        case TransactionMessage.TransactionMessageType.directPayment.rawValue:
            let isTribe = self.chat?.isPublicGroup() ?? false
            let senderAlias = self.senderAlias ?? "Unknown".localized
            let recipientAlias = self.recipientAlias ?? "Unknown".localized
            
            if isTribe {
                if incoming {
                    return String(format: "tribe.payment.received".localized, senderAlias, "\(amountString) sats" , recipientAlias)
                } else {
                    return String(format: "tribe.payment.sent".localized, "\(amountString) sats", recipientAlias)
                }
            } else {
                return "\("payment".localized) \(directionString): \(amountString) sats"
            }
        case TransactionMessage.TransactionMessageType.imageAttachment.rawValue:
            if self.isGif() {
                return "\("gif.capitalize".localized) \(directionString)"
            } else {
                return "\("picture.capitalize".localized) \(directionString)"
            }
        case TransactionMessage.TransactionMessageType.videoAttachment.rawValue:
            return "\("video.capitalize".localized) \(directionString)"
        case TransactionMessage.TransactionMessageType.audioAttachment.rawValue:
            return "\("audio.capitalize".localized) \(directionString)"
        case TransactionMessage.TransactionMessageType.pdfAttachment.rawValue:
            return "PDF \(directionString)"
        case TransactionMessage.TransactionMessageType.fileAttachment.rawValue:
            return "\("file".localized) \(directionString)"
        case TransactionMessage.TransactionMessageType.textAttachment.rawValue:
            return "\("paid.message.capitalize".localized) \(directionString)"
        case TransactionMessage.TransactionMessageType.botResponse.rawValue:
            return "\("bot.response".localized) \(directionString)"
        case TransactionMessage.TransactionMessageType.groupLeave.rawValue,
             TransactionMessage.TransactionMessageType.groupJoin.rawValue,
             TransactionMessage.TransactionMessageType.groupKick.rawValue,
             TransactionMessage.TransactionMessageType.groupDelete.rawValue,
             TransactionMessage.TransactionMessageType.memberRequest.rawValue,
             TransactionMessage.TransactionMessageType.memberApprove.rawValue,
             TransactionMessage.TransactionMessageType.memberReject.rawValue:
            return self.getGroupMessageText(owner: owner, contact: contact).withoutBreaklines
        case TransactionMessage.TransactionMessageType.boost.rawValue:
            return "\(self.getMessageSenderNickname(minimized: true, owner: owner, contact: contact)): Boost"
        case TransactionMessage.TransactionMessageType.purchase.rawValue:
            return "\("purchase.item.description".localized) \(directionString)"
        case TransactionMessage.TransactionMessageType.purchaseAccept.rawValue:
            return "item.purchased".localized
        case TransactionMessage.TransactionMessageType.purchaseDeny.rawValue:
            return "item.purchase.denied".localized
        default: break
        }
        return "\("message.not.supported".localized) \(directionString)"
    }
    
    func getGroupMessageText(
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        var message = "message.not.supported"
        
        switch(type) {
        case TransactionMessageType.groupJoin.rawValue:
            message = getGroupJoinMessageText(owner: owner, contact: contact)
        case TransactionMessageType.groupLeave.rawValue:
            message = getGroupLeaveMessageText(owner: owner, contact: contact)
        case TransactionMessageType.groupKick.rawValue:
            message = "tribe.kick".localized
        case TransactionMessageType.groupDelete.rawValue:
            message = "tribe.deleted".localized
        case TransactionMessageType.memberRequest.rawValue:
            message = String(format: "member.request".localized, getMessageSenderNickname(owner: owner, contact: contact))
        case TransactionMessageType.memberApprove.rawValue:
            message = getMemberApprovedMessageText(owner: owner, contact: contact)
        case TransactionMessageType.memberReject.rawValue:
            message = getMemberDeclinedMessageText(owner: owner, contact: contact)
        default:
            break
        }
        return message
    }
    
    func getMemberDeclinedMessageText(
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        if self.chat?.isMyPublicGroup(ownerPubKey: owner.publicKey) ?? false {
            return String(format: "admin.request.rejected".localized, getMessageSenderNickname(owner: owner, contact: contact))
        } else {
            return "member.request.rejected".localized
        }
    }
    
    func getMemberApprovedMessageText(
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        if self.chat?.isMyPublicGroup(ownerPubKey: owner.publicKey) ?? false {
            return String(format: "admin.request.approved".localized, getMessageSenderNickname(owner: owner, contact: contact))
        } else {
            return "member.request.approved".localized
        }
    }
    
    func getGroupJoinMessageText(
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        return getGroupJoinMessageText(
            senderAlias: getMessageSenderNickname(
                owner: owner,
                contact: contact
            )
        )
    }
    
    func getGroupLeaveMessageText(
        owner: UserContact,
        contact: UserContact?
    ) -> String {
        return getGroupLeaveMessageText(
            senderAlias: getMessageSenderNickname(
                owner: owner,
                contact: contact
            )
        )
    }
    
    func getGroupJoinMessageText(senderAlias: String) -> String {
        return String(format: "has.joined.tribe".localized, senderAlias)
    }
    
    func getGroupLeaveMessageText(senderAlias: String) -> String {
        return String(format: "just.left.tribe".localized, senderAlias)
    }
    
    func getPodcastComment() -> PodcastComment? {
        let messageC = (messageContent ?? "")
        
        if messageC.isPodcastComment {
            let stringWithoutPrefix = messageC.replacingOccurrences(
                of: PodcastFeed.kClipPrefix,
                with: ""
            )
            
            if let data = stringWithoutPrefix.data(using: .utf8) {
                
                if let jsonObject = try? JSON(data: data) {
                    
                    var podcastComment = PodcastComment()
                    podcastComment.feedId = jsonObject["feedID"].stringValue
                    podcastComment.itemId = jsonObject["itemID"].stringValue
                    podcastComment.timestamp = jsonObject["ts"].intValue
                    podcastComment.title = jsonObject["title"].stringValue
                    podcastComment.text = jsonObject["text"].stringValue
                    podcastComment.url = jsonObject["url"].stringValue
                    podcastComment.pubkey = jsonObject["pubkey"].stringValue
                    podcastComment.uuid = self.uuid ?? ""
                    
                    if podcastComment.isValid() {
                        return podcastComment
                    }
                }
            }
        }
        
        return nil
    }
    
    func getBoostAmount() -> Int {
        let messageC = (messageContent ?? "")
        
        let stringWithoutPrefix = messageC.replacingOccurrences(of: PodcastFeed.kBoostPrefix, with: "")
        if let data = stringWithoutPrefix.data(using: .utf8) {
            if let jsonObject = try? JSON(data: data) {
                return jsonObject["amount"].intValue
            }
        }
        return 0
    }
    
    func getTimeStamp() -> Int? {
        let messageC = (messageContent ?? "")
        
        var stringWithoutPrefix = messageC.replacingOccurrences(of: PodcastFeed.kBoostPrefix, with: "")
        stringWithoutPrefix = stringWithoutPrefix.replacingOccurrences(of: PodcastFeed.kClipPrefix, with: "")
        
        if let data = stringWithoutPrefix.data(using: .utf8) {
            if let jsonObject = try? JSON(data: data) {
                return jsonObject["ts"].intValue
            }
        }
        return nil
    }
    
    func shouldAvoidShowingBubble() -> Bool {
        let groupsPinManager = GroupsPinManager.sharedInstance
        let isStandardPIN = groupsPinManager.isStandardPIN
        let isPrivateConversation = !(chat?.isGroup() ?? false)
        let messageSender = getMessageSender()
        
        if isPrivateConversation {
            return (isStandardPIN && !(messageSender?.pin ?? "").isEmpty) || (!isStandardPIN && (messageSender?.pin ?? "").isEmpty)
        } else {
            return (isStandardPIN && !(chat?.pin ?? "").isEmpty) || (!isStandardPIN && (chat?.pin ?? "").isEmpty)
        }
    }
    
    func shouldSendNotification() -> Bool {
        if [TransactionMessage.TransactionMessageType.groupLeave.rawValue, TransactionMessage.TransactionMessageType.groupJoin.rawValue].contains(self.type) {
            let isTribeAdmin = (self.chat?.isMyPublicGroup() ?? false)
            return isTribeAdmin
        }

        if self.type == TransactionMessage.TransactionMessageType.boost.rawValue {
            return getReplyingTo()?.isOutgoing() ?? false
        }
        
        return true
    }
    
    func containsMention() -> Bool {
        guard let chat = self.chat else {
            return false
        }
        
        if let alias = chat.myAlias, !alias.isEmpty {
            return self.messageContent?.lowercased().contains("@\(alias.lowercased())") == true
        } else if let nickname = UserContact.getOwner()?.nickname, !nickname.isEmpty {
            return self.messageContent?.lowercased().contains("@\(nickname.lowercased())") == true
        }
        
        return false
    }
}
