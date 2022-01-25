//
//  ChatSmallAvatarView.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 25/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import SDWebImage

class ChatSmallAvatarView: NSView, LoadableNib {

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var profileImageView: AspectFillNSImageView!
    @IBOutlet weak var profileInitialContainer: NSView!
    @IBOutlet weak var initialsLabel: NSTextField!

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
        profileInitialContainer.layer?.cornerRadius = profileInitialContainer.frame.size.height/2
        profileInitialContainer.layer?.masksToBounds = true
    }
    
    func hideAllElements() {
        profileImageView.isHidden = true
        profileInitialContainer.isHidden = true
    }
    
    func configureFor(message: TransactionMessage, contact: UserContact?, and chat: Chat?) {
        profileImageView.isHidden = true
        profileInitialContainer.isHidden = true
        profileImageView.layer?.borderWidth = 0
        
        if !message.consecutiveMessages.previousMessage {
            
            let senderAvatarURL = message.getMessageSenderProfilePic(chat: chat, contact: contact)
            let senderNickname = message.getMessageSenderNickname()
            let senderColor = ChatHelper.getSenderColorFor(message: message)
            
            showInitials(senderColor: senderColor, senderNickname: senderNickname)
            
            profileImageView.sd_cancelCurrentImageLoad()

            if let senderAvatarURL = senderAvatarURL,
               let url = URL(string: senderAvatarURL) {
                
                profileImageView.sd_setImage(
                    with: url,
                    placeholderImage: NSImage(named: "profile_avatar"),
                    options: [SDWebImageOptions.progressiveLoad, SDWebImageOptions.retryFailed],
                    completed: { (image, error, _, _) in
                        if let image = image, error == nil {
                            self.setImage(image: image)
                        }
                })
            }
        }
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
