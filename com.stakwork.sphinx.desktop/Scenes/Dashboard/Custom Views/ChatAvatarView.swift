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
    
    @IBOutlet weak var profileImageHeight: NSLayoutConstraint!
    @IBOutlet weak var profileImageWidth: NSLayoutConstraint!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        setupViews()
    }
    
    func setupViews() {
        profileImageView.wantsLayer = true
        profileImageView.rounded = true
        profileImageView.layer?.cornerRadius = profileImageView.frame.height / 2
    }
    
    func configureSize(width: CGFloat, height: CGFloat, fontSize: CGFloat) {
        profileImageHeight.constant = height
        profileImageWidth.constant = width
        profileImageView.superview?.layoutSubtreeIfNeeded()
        
        profileInitialsLabel.font = NSFont(name: "Montserrat-Regular", size: fontSize)!
    }
    
    func configureForInvite() {
        resetLayout()
        
        profileImageContainer.isHidden = false
        profileImageView.isHidden = false

        profileImageView.sd_cancelCurrentImageLoad()
        profileImageView.rounded = false
        profileImageView.image = NSImage(named: "inviteQrCode")?.sd_tintedImage(with: NSColor.Sphinx.TextMessages)
    }
    
    func resetLayout() {
        profileImageContainer.isHidden = true
        profileInitialsContainer.isHidden = true
        profileImageView.isHidden = true
        
        profileImageView.rounded = true
        profileImageView.image = nil
    }
    
    func makeImagesCircular(images: [NSView]) {
        for image in images {
            image.wantsLayer = true
            image.layer?.cornerRadius = image.frame.size.height / 2
            image.layer?.masksToBounds = true
        }
    }
    
    func loadWith(
        _ object: ChatListCommonObject?
    ) {
        loadImageFor(
            object,
            in: profileImageView,
            and: profileInitialsContainer
        )
    }
    
    func loadImageFor(
        _ object: ChatListCommonObject?,
        in imageView: AspectFillNSImageView,
        and container: NSView
    ) {
        showInitialsFor(
            object,
            in: imageView,
            and: container
        )
        
        imageView.sd_cancelCurrentImageLoad()

        if let urlString = object?.getPhotoUrl()?.removeDuplicatedProtocol(), let url = URL(string: urlString) {
            
            let transformer = SDImageResizingTransformer(
                size: CGSize(
                    width: imageView.bounds.size.width * 2,
                    height: imageView.bounds.size.height * 2
                ),
                scaleMode: .aspectFill
            )
            
            imageView.sd_setImage(
                with: url,
                placeholderImage: NSImage(named: "profileAvatar"),
                options: [.lowPriority],
                context: [.imageTransformer: transformer],
                progress: nil,
                completed: { (image, error, _, _) in
                    if let image = image, error == nil {
                        self.setImage(image: image, in: imageView, initialsContainer: container)
                    }
                }
            )
        } else {
            container.isHidden = false
            imageView.isHidden = true
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
