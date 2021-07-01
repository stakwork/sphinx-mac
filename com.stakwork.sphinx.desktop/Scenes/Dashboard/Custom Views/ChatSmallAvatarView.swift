//
//  ChatSmallAvatarView.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 25/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

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
            let isTribe = (chat?.isPublicGroup() ?? false)
            
            if let image = contact?.objectPicture, senderAvatarURL != nil && !isTribe {
                self.setImage(image: image)
            } else {
                showInitials(senderColor: senderColor, senderNickname: senderNickname)
                
                if let imageUrl = senderAvatarURL?.trim() {
                    let contactId = contact?.id ?? -1
                    
                    DispatchQueue.global().async {
                        MediaLoader.loadAvatarImage(url: imageUrl, objectId: contactId, completion: { (image, id) in
                            guard let image = image, id == contactId else {
                                return
                            }
                            if !isTribe { contact?.objectPicture = image }
                            DispatchQueue.main.async {
                                self.setImage(image: image)
                            }
                        })
                    }
                }
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
