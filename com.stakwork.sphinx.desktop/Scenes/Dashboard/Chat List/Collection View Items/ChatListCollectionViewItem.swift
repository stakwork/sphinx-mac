//
//  ChatListCollectionViewItem.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class ChatListCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var backgroundColorBox: NSBox!
    @IBOutlet weak var chatAvatarView: ChatAvatarView!
    @IBOutlet weak var badgeView: NSBox!
    @IBOutlet weak var badgeLabel: NSTextField!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet weak var separatorLine: NSBox!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var inviteSignLabel: NSTextField!
    @IBOutlet weak var muteImageView: NSImageView!
    @IBOutlet weak var invitePriceContainer: NSBox!
    @IBOutlet weak var invitePriceLabel: NSTextField!
    
    @IBOutlet weak var nameTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageBottomConstraint: NSLayoutConstraint!
    
    let lockSignWidht: CGFloat = 20.0
    let muteSignWidht: CGFloat = 20.0
    let rowRightMargin: CGFloat = 16.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func configureChatListRow(object: ChatListCommonObject, isLastRow: Bool = false, selected: Bool = false) {
        setSelectedState(selected)
        
        nameLabel.font = Constants.kChatNameFont
        nameLabel.stringValue = object.getName()
        lockSign.isHidden = !object.hasEncryptionKey()
        inviteSignLabel.stringValue = ""

        chatAvatarView.setImages(object: object)

        separatorLine.isHidden = isLastRow
        configureLastMessage(object: object)
        
        configureBadge(count: object.getConversation()?.getReceivedUnseenMessagesCount() ?? 0)

        muteImageView.isHidden = !(object.getConversation()?.isMuted() ?? false)

        resetPriceLayouts()
    }
    
    func setSelectedState(_ selected: Bool) {
        let backColor = selected ? NSColor.Sphinx.ChatListSelected : NSColor.Sphinx.HeaderBG
        backgroundColorBox.fillColor = backColor
        chatAvatarView.setBackgroundColors(color: backColor)
    }
    
    func configureBadge(count: Int) {
        badgeView.wantsLayer = true
        badgeView.layer?.cornerRadius = badgeView.frame.size.height / 2
        badgeView.isHidden = count <= 0
        badgeLabel.stringValue = count > 99 ? "99+" : "\(count)"
    }
        
    func resetPriceLayouts() {
        invitePriceContainer.wantsLayer = true
        invitePriceContainer.layer?.cornerRadius = 3
        invitePriceContainer.isHidden = true
        
        let nameRightC = lockSignWidht + muteSignWidht + rowRightMargin
        setNameRightConstraint(value: nameRightC)
    }
    
    func configureLastMessage(object: ChatListCommonObject) {
        if object.lastMessage?.isFault ?? false {
            object.updateLastMessage()
        }
        
        if let lastMessage = object.lastMessage {
            messageLabel.isHidden = false
            dateLabel.isHidden = false
            
            let newMessage = lastMessage.isNewUnseenMessage()
            messageLabel.font = newMessage ? Constants.kNewMessagePreviewFont : Constants.kMessagePreviewFont
            messageLabel.textColor = newMessage ? NSColor.Sphinx.TextMessages : NSColor.Sphinx.SecondaryText

            dateLabel.stringValue = lastMessage.date.getLastMessageDateFormat()
            messageLabel.stringValue = lastMessage.getMessageDescription()
            setNameTopConstraint(value: Constants.kChatListNamePosition)
        } else {
            messageLabel.isHidden = true
            dateLabel.isHidden = true
            setNameTopConstraint(value: 0)
        }
    }
    
    func setNameTopConstraint(value: CGFloat) {
        if nameTopConstraint.constant != value {
            nameTopConstraint.constant = value
            nameLabel.superview?.layoutSubtreeIfNeeded()
        }
        
        if messageBottomConstraint.constant != Constants.kChatListMessagePosition {
            messageBottomConstraint.constant = Constants.kChatListMessagePosition
            messageLabel.superview?.layoutSubtreeIfNeeded()
        }
    }
    
    func setNameRightConstraint(value: CGFloat) {
        if nameRightConstraint.constant != value {
            nameRightConstraint.constant = value
            nameLabel.superview?.layoutSubtreeIfNeeded()
        }
    }
    
    func configureInvitation(contact: UserContact, isLastRow: Bool = false) {
        backgroundColorBox.fillColor = NSColor.Sphinx.HeaderBG
        
        let inviteString = String(format: "invite.name".localized, contact.nickname ?? "")
        nameLabel.stringValue = inviteString
        messageLabel.stringValue = contact.invite?.welcomeMessage ?? "welcome.to.sphinx".localized
        dateLabel.stringValue = ""
        messageLabel.isHidden = false
        lockSign.isHidden = true
        badgeView.isHidden = true
        muteImageView.isHidden = true
        
        chatAvatarView.configureForInvite()
        
        separatorLine.isHidden = isLastRow
        
        messageLabel.font = Constants.kNewMessagePreviewFont
        messageLabel.textColor = NSColor.Sphinx.TextMessages
        
        messageLabel.isHidden = false
        dateLabel.isHidden = false
        setNameTopConstraint(value: Constants.kChatListNamePosition)
        
        resetPriceLayouts()
        configureInviteStatus(invite: contact.invite)
    }
    
    func configureInviteStatus(invite: UserInvite?) {
        if let invite = invite {
            let (sign, color, text) = invite.getDataForRow()
            
            messageLabel.font = Constants.kMessagePreviewFont

            inviteSignLabel.stringValue = sign
            inviteSignLabel.textColor = color
            messageLabel.stringValue = text

            if let price = invite.price, invite.isPendingPayment(){
                invitePriceContainer.isHidden = false
                invitePriceLabel.stringValue = Int(truncating: price).formattedWithSeparator
                
                let nameRightC = lockSignWidht + muteSignWidht + rowRightMargin + invitePriceContainer.frame.size.width
                setNameRightConstraint(value: nameRightC)
            }
        }
    }
    
}
