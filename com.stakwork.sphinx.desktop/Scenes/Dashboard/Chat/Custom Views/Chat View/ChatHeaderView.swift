//
//  ChatHeaderView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 07/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

protocol ChatHeaderViewDelegate : AnyObject {
    func didTapWebAppButton()
    func didTapMuteButton()
}

class ChatHeaderView: NSView, LoadableNib {
    
    weak var delegate: ChatHeaderViewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var imageContainer: NSView!
    @IBOutlet weak var profileImageView: AspectFillNSImageView!
    @IBOutlet weak var initialsContainer: NSBox!
    @IBOutlet weak var initialsLabel: NSTextField!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var contributionsContainer: NSStackView!
    @IBOutlet weak var contributedSatsLabel: NSTextField!
    @IBOutlet weak var contributionSign: NSTextField!
    @IBOutlet weak var tribePriceLabel: NSTextField!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var boltSign: NSTextField!
    @IBOutlet weak var volumeButton: CustomButton!
    @IBOutlet weak var webAppButton: CustomButton!
    @IBOutlet weak var callButton: CustomButton!
    
    var chat: Chat? = nil
    var contact: UserContact? = nil

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
    }
    
    func configureWith(
        chat: Chat?,
        contact: UserContact?,
        delegate: ChatHeaderViewDelegate
    ) {
        if chat == nil && contact == nil {
            setupDisabledMode()
            return
        }
        
        self.chat = chat
        self.contact = contact
        self.delegate = delegate
        
        setChatInfo()
    }
    
    func setupDisabledMode() {
        nameLabel.stringValue = "Open a conversation to start messaging"
        
        imageContainer.isHidden = true
        contributionsContainer.isHidden = true
        
        lockSign.isHidden = true
        boltSign.isHidden = true
        volumeButton.isHidden = true
        webAppButton.isHidden = true
        callButton.isHidden = true
    }
    
    func setChatInfo() {
        configureHeaderBasicInfo()
        configureEncryptionSign()
        configureWebAppButton()
        setVolumeState()
        configureImageOrInitials()
        configureContributionsAndPrices()
        checkRoute()
    }
    
    func configureHeaderBasicInfo() {
        nameLabel.stringValue = getHeaderName()
        callButton.isHidden = false
    }
    
    func configureEncryptionSign() {
        let isEncrypted = (chat?.isEncrypted() ?? contact?.hasEncryptionKey()) ?? false
        lockSign.stringValue = isEncrypted ? "lock" : "lock_open"
        lockSign.isHidden = false
        
        if let contact = contact, !contact.hasEncryptionKey() {
            forceKeysExchange(contactId: contact.id)
        }
    }
    
    func configureImageOrInitials() {
        imageContainer.isHidden = false
        profileImageView.isHidden = true
        initialsContainer.isHidden = true
        
        profileImageView.sd_cancelCurrentImageLoad()
        
        showInitialsFor(
            contact: contact,
            and: chat
        )
        
        if let imageUrl = getImageUrl()?.trim(), let nsUrl = URL(string: imageUrl) {
            profileImageView.sd_setImage(
                with: nsUrl,
                placeholderImage: NSImage(named: "profile_avatar"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .lowPriority],
                progress: nil,
                completed: { (image, error, _, _) in
                    if (error == nil) {
                        self.initialsContainer.isHidden = true
                        self.profileImageView.isHidden = false
                        self.profileImageView.image = image
                    }
                }
            )
        }
    }
    
    func showInitialsFor(
        contact: UserContact?,
        and chat: Chat?
    ) {
        let name = getHeaderName()
        let color = getInitialsColor()
        
        initialsContainer.isHidden = false
        initialsContainer.fillColor = color
        
        initialsLabel.textColor = NSColor.white
        initialsLabel.stringValue = name.getInitialsFromName()
    }
    
    func getHeaderName() -> String {
        if let chat = chat, chat.isGroup() {
            return chat.getName()
        } else if let contact = contact {
            return contact.getName()
        } else {
            return "name.unknown".localized
        }
    }
    
    func getInitialsColor() -> NSColor {
        if let chat = chat, chat.isGroup() {
            return chat.getColor()
        } else if let contact = contact {
            return contact.getColor()
        } else {
            return NSColor.random()
        }
    }
    
    func getImageUrl() -> String? {
        if let chat = chat, let url = chat.getPhotoUrl(), !url.isEmpty {
            return url.removeDuplicatedProtocol()
        } else if let contact = contact, let url = contact.getPhotoUrl(), !url.isEmpty {
            return url.removeDuplicatedProtocol()
        }
        return nil
    }
    
    func configureContributionsAndPrices() {
        if let prices = chat?.getTribePrices(), chat?.shouldShowPrice() ?? false {
            tribePriceLabel.stringValue = String(
                format: "group.price.text".localized,
                "\(prices.0)",
                "\(prices.1)"
            )
            contributionsContainer.isHidden = false
        } else {
            contributionsContainer.isHidden = true
        }
        
        contributionSign.isHidden = true
        contributedSatsLabel.isHidden = true
    }
    
    func configureWebAppButton() {
        webAppButton.isHidden = true
    }
    
    func setVolumeState() {
        volumeButton.image = NSImage(
            named: chat?.isMuted() ?? false ? "muteOnIcon" : "muteOffIcon"
        )
        volumeButton.isHidden = false
    }
    
    func checkRoute() {
        boltSign.isHidden = false
        
        API.sharedInstance.checkRoute(
            chat: self.chat,
            contact: self.contact,
            callback: { success in
                
            DispatchQueue.main.async {
                self.boltSign.textColor = success ? HealthCheckView.kConnectedColor : HealthCheckView.kNotConnectedColor
            }
        })
    }
    
    func forceKeysExchange(contactId: Int) {
        UserContactsHelper.exchangeKeys(id: contactId)
    }
}
