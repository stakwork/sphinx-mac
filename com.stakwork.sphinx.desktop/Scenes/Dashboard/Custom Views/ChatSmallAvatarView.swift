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
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        profileImageView.isHidden = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    private func setup() {
        profileInitialContainer.wantsLayer = true
        profileInitialContainer.layer?.cornerRadius = self.bounds.height/2
        profileInitialContainer.layer?.masksToBounds = true
        
        avatarButton.cursor = .pointingHand
    }
    
    func setInitialLabelSize(size: Double) {
        initialsLabel.font = NSFont(name: "Montserrat-Regular", size: size)!
    }
    
    @IBAction func buttonClicked(_ sender: NSButton) {
        delegate?.didClickAvatarView()
    }
    
    func hideAllElements() {
        profileImageView.isHidden = true
        profileInitialContainer.isHidden = true
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
        profileImageView.layer?.borderWidth = 0
        
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
    
    func configureForUserWith(
        color: NSColor,
        alias: String?,
        picture: String?
    ) {
        profileImageView.sd_cancelCurrentImageLoad()
        
        profileImageView.isHidden = true
        profileInitialContainer.isHidden = true
        profileImageView.layer?.borderWidth = 0
        
        showInitials(
            senderColor: color,
            senderNickname: alias ?? "Unknown"
        )
        
        if let pic = picture, let url = URL(string: pic) {
            showImageWith(url: url)
        }
    }
    
    func showImageWith(
        url: URL
    ) {
        let transformer = SDImageResizingTransformer(
            size: CGSize(
                width: profileImageView.bounds.size.width * 2,
                height: profileImageView.bounds.size.height * 2
            ),
            scaleMode: .aspectFill
        )
        
        profileImageView.sd_setImage(
            with: url,
            placeholderImage: NSImage(named: "profile_avatar"),
            options: [.lowPriority, .avoidDecodeImage],
            context: [.imageTransformer: transformer],
            progress: nil,
            completed: { (image, error, _, _) in
                if let image = image, error == nil {
                    self.setImage(image: image)
                }
            }
        )
    }
    
    func setImage(image: NSImage) {
        DispatchQueue.main.async {
            self.profileInitialContainer.isHidden = true
            self.profileImageView.isHidden = false
            self.profileImageView.bordered = false
            self.profileImageView.image = image
        }
    }
    
    func showInitials(senderColor: NSColor, senderNickname: String) {        
        profileInitialContainer.isHidden = false
        profileInitialContainer.wantsLayer = true
        profileInitialContainer.layer?.backgroundColor = senderColor.cgColor
        initialsLabel.textColor = NSColor.white
        initialsLabel.stringValue = senderNickname.getInitialsFromName()
    }
}
