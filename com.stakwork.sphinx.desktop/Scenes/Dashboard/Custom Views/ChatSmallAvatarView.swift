//
//  ChatSmallAvatarView.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 25/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import SDWebImage

protocol ChatSmallAvatarViewDelegate: AnyObject {
    func didClickAvatarView()
}

class ChatSmallAvatarView: NSView, LoadableNib {
    
    weak var delegate: ChatSmallAvatarViewDelegate?

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var profileImageView: AspectFillNSImageView!
    @IBOutlet weak var profileInitialContainer: NSView!
    @IBOutlet weak var initialsLabel: NSTextField!
    @IBOutlet weak var avatarButton: CustomButton!
    
    var imageUrl: String? = nil

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    private func setup() {
        profileImageView.wantsLayer = true
        profileImageView.rounded = true
        profileImageView.layer?.cornerRadius = profileImageView.frame.height / 2
        
        profileInitialContainer.wantsLayer = true
        profileInitialContainer.layer?.cornerRadius = self.bounds.height/2
        profileInitialContainer.layer?.masksToBounds = true
     
        avatarButton.cursor = .pointingHand
    }
    
    func setInitialLabelSize(size: Double) {
        initialsLabel.font = NSFont(name: "Montserrat-Regular", size: size)!
    }
    
    @IBAction func buttonClicked(_ sender: NSButton) {
        if profileImageView.isHidden && profileInitialContainer.isHidden {
            return
        }
        delegate?.didClickAvatarView()
    }
    
    func configureFor(
        message: TransactionMessage,
        contact: UserContact?,
        chat: Chat?,
        with delegate: ChatSmallAvatarViewDelegate? = nil
    ) {
        guard let owner = UserContact.getOwner() else {
            return
        }
        
        self.delegate = delegate
        
        profileImageView.isHidden = true
        profileInitialContainer.isHidden = true
        
        if !message.consecutiveMessages.previousMessage {
            
            let senderAvatarURL = message.getMessageSenderProfilePic(chat: chat, contact: contact)
            let senderNickname = message.getMessageSenderNickname(owner: owner, contact: nil)
            let senderColor = ChatHelper.getSenderColorFor(message: message)
            
            showInitials(senderColor: senderColor, senderNickname: senderNickname)
            
            profileImageView.sd_cancelCurrentImageLoad()

            if let senderAvatarURL = senderAvatarURL,
               let url = URL(string: senderAvatarURL) {
                
                showImageWith(url: url)
            }
        }
    }
    
    func configureForSenderWith(
        message: TransactionMessage
    ) {
        configureForUserWith(
            color: ChatHelper.getSenderColorFor(message: message),
            alias: message.senderAlias,
            picture: message.senderPic
        )
    }
    
    func configureForRecipientWith(
        message: TransactionMessage
    ) {
        configureForUserWith(
            color: ChatHelper.getRecipientColorFor(message: message),
            alias: message.recipientAlias,
            picture: message.recipientPic
        )
    }
    
    func resetView() {
        profileImageView.isHidden = false
        profileImageView.image = NSImage(named: "profileAvatar")
        
        profileInitialContainer.isHidden = true
    }
    
    func configureForUserWith(
        color: NSColor,
        alias: String?,
        picture: String?,
        radius: CGFloat? = nil,
        image: NSImage? = nil,
        delegate: ChatSmallAvatarViewDelegate? = nil
    ) {
        self.delegate = delegate
        
        profileImageView.sd_cancelCurrentImageLoad()
        profileImageView.radius = radius ?? profileImageView.frame.height / 2
        
        showInitials(
            senderColor: color,
            senderNickname: alias ?? "Unknown"
        )
        
        if let image = image {
            profileInitialContainer.isHidden = true
            profileImageView.isHidden = false
            profileImageView.image = image
        } else if let pic = picture, let url = URL(string: pic) {
            showImageWith(url: url)
        }
    }
    
    func showImageWith(
        url: URL
    ) {
        if let imageUrl = imageUrl, imageUrl == url.absoluteString {
            profileInitialContainer.isHidden = true
            profileImageView.isHidden = false
            return
        }
        
        let transformer = SDImageResizingTransformer(
            size: CGSize(
                width: profileImageView.bounds.size.width * 2,
                height: profileImageView.bounds.size.height * 2
            ),
            scaleMode: .aspectFill
        )
        
        profileInitialContainer.isHidden = true
        self.imageUrl = url.absoluteString
        
        profileImageView.sd_setImage(
            with: url,
            placeholderImage: NSImage(named: "profileAvatar"),
            options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .progressiveLoad],
            context: [.imageTransformer: transformer],
            progress: nil,
            completed: { (image, error, _, _) in
                if let image = image, error == nil {
                    self.profileImageView.image = image
                    self.profileImageView.isHidden = false
                }
            }

        )
    }
    
    func showInitials(senderColor: NSColor, senderNickname: String) {
        profileImageView.isHidden = true
        profileInitialContainer.isHidden = false
        profileInitialContainer.wantsLayer = true
        profileInitialContainer.layer?.backgroundColor = senderColor.cgColor
        initialsLabel.textColor = NSColor.white
        initialsLabel.stringValue = senderNickname.getInitialsFromName()
    }
}
