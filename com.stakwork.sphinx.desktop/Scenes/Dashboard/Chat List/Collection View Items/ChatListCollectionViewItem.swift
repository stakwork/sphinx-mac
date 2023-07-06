//
//  ChatListCollectionViewItem.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import SDWebImage

class ChatListCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var backgroundBox: NSBox!
    @IBOutlet weak var chatImageView: AspectFillNSImageView!
    @IBOutlet weak var chatInitialsView: NSBox!
    @IBOutlet weak var chatInitialsLabel: NSTextField!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var lockSignLabel: NSTextField!
    @IBOutlet weak var inviteIconLabel: NSTextField!
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var muteImageView: NSImageView!
    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet weak var invitePriceContainer: NSBox!
    @IBOutlet weak var invitePriceLabel: NSTextField!
    @IBOutlet weak var mentionsBadgeContainer: NSBox!
    @IBOutlet weak var mentionsBadgeLabel: NSTextField!
    @IBOutlet weak var unreadMessageBadgeContainer: NSBox!
    @IBOutlet weak var unreadMessageBadgeLabel: NSTextField!
    
    
    var chatListObject: ChatListCommonObject? {
        didSet {
            guard let chatListObject = chatListObject else { return }
            DispatchQueue.main.async {
                self.render(with: chatListObject)
  
            }
        }
    }
    
    var owner: UserContact!
    
    var rowSelected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    func setupViews() {
        chatImageView.rounded = true
        chatImageView.gravity = .resizeAspectFill
        
        chatInitialsView.wantsLayer = true
        chatInitialsView?.layer?.cornerRadius = chatInitialsView.frame.height / 2
        
        invitePriceContainer.wantsLayer = true
        invitePriceContainer.layer?.cornerRadius = 2
        
        // Clear initial contents
        unreadMessageBadgeContainer.isHidden = true
        mentionsBadgeContainer.isHidden = true
        
        nameLabel.stringValue = ""
        messageLabel.stringValue = ""
        dateLabel.stringValue = ""
        
        lockSignLabel.isHidden = true
        muteImageView.isHidden = true
        inviteIconLabel.isHidden = true
        invitePriceContainer.isHidden = true
    }
    
    private func render(with chatListObject: ChatListCommonObject) {
        backgroundBox.fillColor = rowSelected ? NSColor.Sphinx.ChatListSelected : NSColor.Sphinx.HeaderBG
        
        nameLabel.font = Constants.kChatNameFont
        
        if chatListObject.isPending() {
            
            let inviteString = String(
                format: "invite.name".localized,
                chatListObject.getName()
            )
            nameLabel.stringValue = inviteString
            
            muteImageView.isHidden = true
            lockSignLabel.isHidden = true
            
        } else {
            
            if hasUnreadMessages {
                nameLabel.font = nameLabel.font?.bold()
            }
            
            nameLabel.stringValue = chatListObject.getName()
            muteImageView.isHidden = (chatListObject.getChat()?.isMuted() ?? false) == false
            lockSignLabel.isHidden = chatListObject.hasEncryptionKey() == false
        }
        
        renderLastMessage(for: chatListObject)
        renderBadgeView(for: chatListObject)
        renderMentionsView(for: chatListObject)
        renderContactImageViews(for: chatListObject)
        renderInvitePrice(for: chatListObject)
    }
    
    private func renderBadgeView(for chatListObject: ChatListCommonObject) {
        guard hasUnreadMessages else {
            unreadMessageBadgeContainer.isHidden = true
            return
        }
        
        guard chatListObject.isConfirmed() else {
            unreadMessageBadgeContainer.isHidden = true
            return
        }
        
        unreadMessageBadgeContainer.isHidden = false
        
        let unreadMCount = unreadMessageCount
        unreadMessageBadgeLabel.stringValue = unreadMCount > 99 ? "99+" : "\(unreadMCount)"
        
        if chatListObject.getChat()?.isMuted() == true || chatListObject.getChat()?.isOnlyMentions() == true {
            unreadMessageBadgeContainer.alphaValue = 0.2
            unreadMessageBadgeContainer.fillColor = .Sphinx.WashedOutReceivedText
        } else {
            unreadMessageBadgeContainer.alphaValue = 1.0
            unreadMessageBadgeContainer.fillColor = .Sphinx.PrimaryBlue
        }
        
        unreadMessageBadgeContainer.wantsLayer = true
        unreadMessageBadgeContainer.makeCircular()
    }
    
    private func renderMentionsView(for chatListObject: ChatListCommonObject) {
        guard hasUnreadMentions else {
            mentionsBadgeContainer.isHidden = true
            return
        }
        
        guard chatListObject.isConfirmed() else {
            mentionsBadgeContainer.isHidden = true
            return
        }
        
        mentionsBadgeContainer.isHidden = false
        
        let unreadMCount = unreadMentionsCount
        mentionsBadgeLabel.stringValue = unreadMCount > 99 ? "@ 99+" : "@ \(unreadMCount)"
        
        mentionsBadgeContainer.wantsLayer = true
        mentionsBadgeContainer.makeCircular()
    }
    
    private func renderContactImageViews(for chatListObject: ChatListCommonObject) {
        
        chatImageView.sd_cancelCurrentImageLoad()

        if chatListObject.isPending() {

            chatImageView.contentTintColor = NSColor.Sphinx.TextMessages
            chatImageView.layer?.cornerRadius = 0

            chatInitialsView.isHidden = true
            chatImageView.isHidden = false
            chatImageView.image = NSImage(named: "inviteQrCode")

        } else {

            chatImageView.layer?.cornerRadius = chatImageView.frame.height / 2

            chatInitialsView.isHidden = false
            chatImageView.isHidden = true
            
            renderContactInitialsLabel(for: chatListObject)

            if
                let imageURLPath = chatListObject.getPhotoUrl()?.removeDuplicatedProtocol(),
                let imageURL = URL(string: imageURLPath)
            {
                chatImageView.sd_setImage(
                    with: imageURL,
                    placeholderImage: NSImage(named: "profile_avatar"),
                    options: .lowPriority,
                    progress: nil,
                    completed: { [unowned self] (image, error,_,_) in
                        if (error == nil) {
                            self.chatInitialsView.isHidden = true
                            self.chatImageView.isHidden = false
                            self.chatImageView.image = image
                        }
                    }
                )
            }
        }
    }
    
    private func renderContactInitialsLabel(for chatListObject: ChatListCommonObject) {
        let senderInitials = chatListObject.getName().getInitialsFromName()
        let senderColor = chatListObject.getColor()
        
        chatInitialsView.fillColor = senderColor
        chatInitialsLabel.textColor = .white
        chatInitialsLabel.stringValue = senderInitials
    }
    
    private func renderLastMessage(for chatListObject: ChatListCommonObject) {
        if let invite = chatListObject.getInvite(), chatListObject.isPending() {
            
            let (icon, iconColor, text) = invite.getDataForRow()
            
            inviteIconLabel.stringValue = icon
            inviteIconLabel.textColor = iconColor
            inviteIconLabel.isHidden = false
            
            messageLabel.superview?.isHidden = false
            messageLabel.stringValue = text
            dateLabel.isHidden = true
            
            messageLabel.font = Constants.kNewMessagePreviewFont
            messageLabel.textColor = .Sphinx.TextMessages
            
        } else {
            
            inviteIconLabel.isHidden = true
            
            if let lastMessage = chatListObject.lastMessage {
                
                messageLabel.font = hasUnreadMessages ?
                    Constants.kNewMessagePreviewFont
                    : Constants.kMessagePreviewFont
                
                messageLabel.textColor = hasUnreadMessages ?
                    .Sphinx.TextMessages
                    : .Sphinx.SecondaryText
                
                messageLabel.stringValue = lastMessage.getMessageContentPreview(
                    owner: self.owner,
                    contact: chatListObject.getContact()
                )
                
                dateLabel.stringValue = lastMessage.messageDate.getLastMessageDateFormat()
                
                messageLabel.superview?.isHidden = false
                dateLabel.isHidden = false
            } else {
                messageLabel.superview?.isHidden = true
                dateLabel.isHidden = true
            }
        }
    }
    
    private func renderInvitePrice(for chatListObject: ChatListCommonObject) {
        if let invite = chatListObject.getInvite(),
           let price = invite.price,
           chatListObject.isPending() && invite.isPendingPayment() && !invite.isPaymentProcessed() {
            
            invitePriceContainer.isHidden = false
            invitePriceLabel.stringValue = Int(truncating: price).formattedWithSeparator
        } else {
            invitePriceContainer.isHidden = true
        }
    }
}

// MARK: -  Computeds
extension ChatListCollectionViewItem {
    
    var unreadMessageCount: Int {
        if chatListObject?.isSeen(ownerId: owner.id) == true {
            return 0
        }
        return chatListObject?.getChat()?.getReceivedUnseenMessagesCount() ?? 0
    }
    
    var hasUnreadMessages: Bool { unreadMessageCount > 0 }
    
    var unreadMentionsCount: Int {
        if chatListObject?.isSeen(ownerId: owner.id) == true {
            return 0
        }
        return chatListObject?.getChat()?.getReceivedUnseenMentionsCount() ?? 0
    }
    
    var hasUnreadMentions: Bool { unreadMentionsCount > 0 }
}

// MARK: - Static Properties
extension ChatListCollectionViewItem {
    static let reuseID = "ChatListCollectionViewItem"
    
    static let nib: NSNib? = {
        NSNib(nibNamed: "ChatListCollectionViewItem", bundle: nil)
    }()
}
