//
//  ChatAvatarView.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 15/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import SDWebImage

class ChatAvatarView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var profileImageContainer: NSView!
    @IBOutlet weak var profileImageView: AspectFillNSImageView!
    @IBOutlet weak var profileInitialsContainer: NSView!
    @IBOutlet weak var profileInitialsLabel: NSTextField!
    
    @IBOutlet weak var groupImagesContainer: NSView!
    @IBOutlet weak var groupImage2Container: NSBox!
    @IBOutlet weak var groupImage1: AspectFillNSImageView!
    @IBOutlet weak var initialsContainer1: NSView!
    @IBOutlet weak var initialsLabel1: NSTextField!
    @IBOutlet weak var groupImage2: AspectFillNSImageView!
    @IBOutlet weak var initialsContainer2: NSView!
    @IBOutlet weak var initialsLabel2: NSTextField!
    
    @IBOutlet weak var profileImageHeight: NSLayoutConstraint!
    @IBOutlet weak var profileImageWidth: NSLayoutConstraint!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        setBackgroundColors(color: NSColor.Sphinx.HeaderBG)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    func configureSize(width: CGFloat, height: CGFloat, fontSize: CGFloat) {
        profileImageHeight.constant = height
        profileImageWidth.constant = width
        profileImageView.superview?.layoutSubtreeIfNeeded()
        
        profileInitialsLabel.font = NSFont(name: "Montserrat-Regular", size: fontSize)!
    }
    
    func setBackgroundColors(color: NSColor) {
        groupImage2Container.fillColor = color
    }
    
    func configureForInvite() {
        resetLayout()
        
        profileImageContainer.isHidden = false
        profileImageView.isHidden = false

        profileImageView.sd_cancelCurrentImageLoad()
        profileImageView.rounded = false
        profileImageView.image = NSImage(named: "inviteQrCode")?.sd_tintedImage(with: NSColor.Sphinx.TextMessages)
    }
    
    func setImages(object: ChatListCommonObject?) {
        resetLayout()
        
        guard let object = object else {
            profileImageContainer.isHidden = true
            groupImagesContainer.isHidden = true
            return
        }

        makeImagesCircular(images: [groupImage2Container])
        
        let shouldShowSingleImage = object.shouldShowSingleImage()
        let contacts = object.getChatContacts()

        profileImageContainer.isHidden = !shouldShowSingleImage
        groupImagesContainer.isHidden = shouldShowSingleImage
        
        func getContactWithIndex(contacts: [UserContact], index: Int) -> UserContact? {
            return contacts.count >= index + 1 ? contacts[index] : nil
        }
        
        if shouldShowSingleImage {
            loadImageFor(object, in: profileImageView, and: profileInitialsContainer)
        } else {
            let orderedContacts = contacts.sorted(by: { (!$0.isOwner && $0.avatarUrl != nil) && ($1.isOwner || $1.avatarUrl == nil) })
            
            loadImageFor(getContactWithIndex(contacts: orderedContacts, index: 0), in: groupImage2, and: initialsContainer2)
            loadImageFor(getContactWithIndex(contacts: orderedContacts, index: 1), in: groupImage1, and: initialsContainer1)
        }
    }
    
    func resetLayout() {
        profileImageContainer.isHidden = true
        profileInitialsContainer.isHidden = true
        profileImageView.isHidden = true
        
        groupImagesContainer.isHidden = true
        
        groupImage1.isHidden = true
        initialsContainer1.isHidden = true
        
        groupImage2.isHidden = true
        initialsContainer2.isHidden = true
        
        profileImageView.rounded = true
        profileImageView.image = nil
        groupImage2.image = nil
        groupImage1.image = nil
    }
    
    func makeImagesCircular(images: [NSView]) {
        for image in images {
            image.wantsLayer = true
            image.layer?.cornerRadius = image.frame.size.height / 2
            image.layer?.masksToBounds = true
        }
    }
    
    func loadImageFor(_ object: ChatListCommonObject?, in imageView: AspectFillNSImageView, and container: NSView) {
        showInitialsFor(object, in: imageView, and: container)
        
        imageView.sd_cancelCurrentImageLoad()

        if let urlString = object?.getPhotoUrl()?.removeDuplicatedProtocol(),
           let url = URL(string: urlString) {

            imageView.sd_setImage(
                with: url,
                placeholderImage: NSImage(named: "profile_avatar"),
                options: [SDWebImageOptions.retryFailed],
                completed: { (image, error, _, _) in
                    if let image = image, error == nil {
                        self.setImage(image: image, in: imageView, initialsContainer: container)
                    }
            })
        }
    }
    
    func setImage(image: NSImage, in imageView: AspectFillNSImageView, initialsContainer: NSView) {
        initialsContainer.isHidden = true
        imageView.isHidden = false
        imageView.bordered = false
        imageView.image = image
    }
    
    func showInitialsFor(_ object: ChatListCommonObject?, in imageView: AspectFillNSImageView, and container: NSView) {
        let senderInitials = object?.getName().getInitialsFromName() ?? "UK"
        let senderColor = object?.getColor()
        
        container.isHidden = false
        imageView.bordered = false
        imageView.image = nil
        
        container.wantsLayer = true
        container.layer?.cornerRadius = container.frame.size.height / 2
        container.layer?.backgroundColor = senderColor?.cgColor
        
        if let label = container.subviews[0] as? NSTextField {
            label.stringValue = senderInitials
        }
    }
}
