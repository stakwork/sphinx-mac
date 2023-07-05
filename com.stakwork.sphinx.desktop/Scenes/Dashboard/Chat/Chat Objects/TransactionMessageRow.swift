//
//  TransactionMessageRow.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 18/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import SwiftyJSON

class TransactionMessageRow : NSObject {
    
    var transactionMessage: TransactionMessage! = nil
    var headerDate : Date?
    
    var shouldShowRightLine = false
    var shouldShowLeftLine = false
    
    var audioHelper: AudioPlayerHelper? = nil
    var podcastPlayerHelper: PodcastRowPlayerHelper? = nil
    
    var isPodcastLive = false
    
    init(message: TransactionMessage? = nil) {
        self.transactionMessage = message
    }
    
    func configureAudioPlayer() {
        if audioHelper == nil {
            audioHelper = AudioPlayerHelper()
        }
    }
    
    func configurePodcastPlayer() {
        if podcastPlayerHelper == nil {
            podcastPlayerHelper = PodcastRowPlayerHelper()
        }
    }
    
    func getConsecutiveMessages() -> TransactionMessage.ConsecutiveMessages {
        if self.isPodcastLive {
            return TransactionMessage.ConsecutiveMessages(previousMessage: false, nextMessage: false)
        }
        return self.transactionMessage.consecutiveMessages
    }
    
    func getMessageContent() -> String {
        if let message = transactionMessage, message.bubbleMessageContentString != "" {
            return message.bubbleMessageContentString ?? ""
        }
        return ""
    }
    
    func getMessageAttributes() -> (String, NSColor, NSFont) {
        let regularBigFont = Constants.kMessageFont
        let mediumSmallFont = Constants.kBoldSmallMessageFont
        let messageTextColor = Constants.kMessageTextColor
        let encryptionMessageColor = Constants.kEncryptionMessageColor
        
        guard let message = transactionMessage else {
            return ("", messageTextColor, regularBigFont)
        }
        
        let messageContent = message.bubbleMessageContentString ?? ""
        let canDecrypt = canBeDecrypted()
        let messagePendingAttachment = message.isPendingPaidMessage() || message.isLoadingPaidMessage()
        var font = canDecrypt && !messagePendingAttachment ? regularBigFont : mediumSmallFont
        let textColor = canDecrypt ? messageTextColor : encryptionMessageColor
        
        font = isEmojisMessage() ? Constants.kEmojisFont : font
        
        return (messageContent, textColor, font)
    }
    
    func isEmojisMessage() -> Bool {
        let messageContent = transactionMessage.bubbleMessageContentString ?? ""
        return messageContent.length < 4 && messageContent.length > 0 && messageContent.containsOnlyEmoji && transactionMessage.isTextMessage()
    }
    
    func getMessageLink() -> String {
        return self.getMessageContent().stringFirstLink
    }
    
    func getStatus() -> Int {
        if let message = transactionMessage {
            let status = message.status
            return status
        }
        return TransactionMessage.TransactionMessageStatus.pending.rawValue
    }
    
    func getMessageId() -> Int? {
        if let message = transactionMessage {
            return message.id
        }
        return nil
    }
    
    func getType() -> Int? {
        if let message = transactionMessage {
            return message.getType()
        }
        return nil
    }
    
    func getAmountString() -> String {
        let amountNumber = self.transactionMessage?.amount ?? NSDecimalNumber(value: 0)
        let amountString = Int(truncating: amountNumber).formattedWithSeparator
        return amountString
    }
    
    func isIncoming() -> Bool {
        if let message = transactionMessage {
            return message.isIncoming()
        }
        return false
    }
    
    func canBeDecrypted() -> Bool {
        return transactionMessage?.canBeDecrypted() ?? false
    }
    
    func isPaymentWithImage() -> Bool {
        return transactionMessage?.isPaymentWithImage() ?? false
    }
    
    func shouldShowPaidAttachmentView() -> Bool {
        if let message = transactionMessage {
            return message.shouldShowPaidAttachmentView()
        }
        return false
    }
    
    func shouldLoadLinkPreview() -> Bool {
        return self.getMessageContent().hasLinks && !isPodcastComment &&
            (transactionMessage.type == TransactionMessage.TransactionMessageType.message.rawValue || transactionMessage.isPaidMessage())
    }
    
    func shouldShowLinkPreview() -> Bool {
        return shouldLoadLinkPreview() && transactionMessage.linkHasPreview
    }
    
    func shouldLoadTribeLinkPreview() -> Bool {
        return self.getMessageContent().hasTribeLinks && !isPodcastComment &&
            (transactionMessage.type == TransactionMessage.TransactionMessageType.message.rawValue || transactionMessage.isPaidMessage())
    }
    
    func shouldShowTribeLinkPreview() -> Bool {
        return shouldLoadTribeLinkPreview() && transactionMessage.linkHasPreview
    }
    
    func shouldLoadPubkeyPreview() -> Bool {
        return self.getMessageContent().hasPubkeyLinks && !isPodcastComment &&
            (transactionMessage.type == TransactionMessage.TransactionMessageType.message.rawValue || transactionMessage.isPaidMessage())
    }
    
    func shouldShowPubkeyPreview() -> Bool {
        return shouldLoadPubkeyPreview()
    }
    
    func isJoinedTribeLink(uuid: String? = nil) -> Bool {
        if let uuid = uuid {
            if let _ = Chat.getChatWith(uuid: uuid) {
                return true
            }
        }
        
        let tribeLink = getMessageContent().stringFirstTribeLink
        if let tribeInfo = GroupsManager.sharedInstance.getGroupInfo(query: tribeLink), let uuid = tribeInfo.uuid, !uuid.isEmpty {
            if let _ = Chat.getChatWith(uuid: uuid) {
                return true
            }
        }
        return false
    }
    
    func isExistingContactPubkey() -> (Bool, UserContact?) {
        return getMessageContent().isExistingContactPubkey()
    }
    
    func getPodcastComment() -> PodcastComment? {
        return transactionMessage?.getPodcastComment()
    }
    
    var isDayHeader: Bool {
        get {
            return headerDate != nil
        }
    }
    
    var isDirectPayment: Bool {
        get {
            if let message = transactionMessage {
                return message.isDirectPayment()
            }
            return false
        }
    }
    
    var isAttachment: Bool {
        get {
            if let message = transactionMessage {
                return message.isAttachment()
            }
            return false
        }
    }
    
    var isMediaAttachment: Bool {
        get {
            if let message = transactionMessage {
                return message.isMediaAttachment()
            }
            return false
        }
    }
    
    var isReply: Bool {
        get {
            if let message = transactionMessage {
                return message.isReply()
            }
            return false
        }
    }
    
    var isPaidAttachment: Bool {
        get {
            if let message = transactionMessage {
                return message.isPaidAttachment()
            }
            return false
        }
    }
    
    var isPaidSentAttachment: Bool {
        get {
            if let message = transactionMessage {
                return message.isPaidAttachment() && message.isOutgoing()
            }
            return false
        }
    }
    
    var isPendingPaidMessage: Bool {
        get {
            if let message = transactionMessage {
                return message.isPendingPaidMessage()
            }
            return false
        }
    }
    
    var encrypted: Bool {
        get {
            if let message = transactionMessage {
                return message.encrypted
            }
            return false
        }
    }
    
    var date: Date? {
        get {
            if let message = transactionMessage {
                return message.date
            }
            return nil
        }
    }
    
    var chat: Chat? {
        get {
            if let message = transactionMessage, let chat = message.chat {
                return chat
            }
            return nil
        }
    }
    
    var isCallLink: Bool {
        get {
            return (transactionMessage?.isCallLink() ?? false)
        }
    }
    
    var isGiphy: Bool {
        get {
            return (transactionMessage?.isGiphy() ?? false)
        }
    }
    
    var isPodcastComment: Bool {
        get {
            return (transactionMessage?.isPodcastComment() ?? false)
        }
    }
    
    var isPodcastBoost: Bool {
        get {
            return (transactionMessage?.isPodcastBoost() ?? false)
        }
    }
    
    var isBoosted: Bool {
        get {
            return transactionMessage?.isBoosted() ?? false
        }
    }
}
