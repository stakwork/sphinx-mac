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
    func didClickThreadsButton()
    func didClickWebAppButton()
    func didClickMuteButton()
    func didClickCallButton()
    func didClickHeaderButton()
    func didClickSearchButton()
    func didClickSecondBrainAppButton()
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
    @IBOutlet weak var secondBrainButton: CustomButton!
    @IBOutlet weak var callButton: CustomButton!
    @IBOutlet weak var headerButton: CustomButton!
    @IBOutlet weak var threadsButton: CustomButton!
    @IBOutlet weak var searchButton: CustomButton!
    
    var chat: Chat? = nil
    var contact: UserContact? = nil

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setupView()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setupView()
    }
    
    func setupView() {
        profileImageView.wantsLayer = true
        profileImageView.rounded = true
        profileImageView.layer?.cornerRadius = profileImageView.frame.height / 2
        profileImageView.gravity = .resizeAspectFill
        
        volumeButton.cursor = .pointingHand
        webAppButton.cursor = .pointingHand
        secondBrainButton.cursor = .pointingHand
        callButton.cursor = .pointingHand
        headerButton.cursor = .pointingHand
        threadsButton.cursor = .pointingHand
        searchButton.cursor = .pointingHand
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
        secondBrainButton.isHidden = true
        callButton.isHidden = true
        threadsButton.isHidden = true
        searchButton.isHidden = true
    }
    
    func setChatInfo() {
        configureHeaderBasicInfo()
        configureEncryptionSign()
        setVolumeState()
        configureImageOrInitials()
        configureContributionsAndPrices()
    }
    
    func configureHeaderBasicInfo() {
        searchButton.isHidden = false
        
        nameLabel.stringValue = getHeaderName()
        callButton.isHidden = false
        
        threadsButton.isHidden = chat?.isConversation() ?? true
    }
    
    func configureEncryptionSign() {
        let isEncrypted = (contact?.status == UserContact.Status.Confirmed.rawValue) || (chat?.status == Chat.ChatStatus.approved.rawValue)
        lockSign.stringValue = isEncrypted ? "lock" : "lock_open"
        lockSign.isHidden = false
        
        if let contact = contact, !contact.hasEncryptionKey() {
            forceKeysExchange(contactId: contact.id)
        }
    }
    
    func configureImageOrInitials() {
        if let _ = profileImageView.image {
            return
        }
        
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
                placeholderImage: NSImage(named: "profileAvatar"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly],
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
    
    func configureContributions() {
        if let contentFeed = chat?.contentFeed, !contentFeed.feedID.isEmpty {
            let isMyTribe = (chat?.isMyPublicGroup() ?? false)
            let label = isMyTribe ? "earned.sats".localized : "contributed.sats".localized
            let sats = PodcastPaymentsHelper.getSatsEarnedFor(contentFeed.feedID)
            
            contributionSign.isHidden = false
            contributedSatsLabel.isHidden = false
        
            contributedSatsLabel.stringValue = String(format: label, sats)
        }
    }
    
    func setVolumeState() {
        volumeButton.image = NSImage(
            named: chat?.isMuted() ?? false ? "muteOnIcon" : "muteOffIcon"
        )
        volumeButton.isHidden = false
    }
    
    func toggleWebAppIcon() {
        webAppButton.isHidden = !(chat?.hasWebApp() ?? false)
    }
    
    func toggleSecondBrainAppIcon() {
        secondBrainButton.isHidden = !(chat?.hasSecondBrainApp() ?? false)
    }
    
    func checkRoute() {
        if self.chat == nil && self.contact == nil {
            return
        }
        
        boltSign.isHidden = false

        let success = (contact?.status == UserContact.Status.Confirmed.rawValue) || (chat?.status == Chat.ChatStatus.approved.rawValue)
        self.boltSign.textColor = success ? HealthCheckView.kConnectedColor : HealthCheckView.kNotConnectedColor
    }
    
    func forceKeysExchange(contactId: Int) {
        UserContactsHelper.exchangeKeys(id: contactId)
    }
    
    @IBAction func threadsButtonClicked(_ sender: Any) {
        delegate?.didClickThreadsButton()
    }
    
    @IBAction func webAppButtonClicked(_ sender: Any) {
        delegate?.didClickWebAppButton()
    }
    
    @IBAction func secondBrainAppButtonClicked(_ sender: Any) {
        delegate?.didClickSecondBrainAppButton()
    }
    
    @IBAction func muteButtonClicked(_ sender: Any) {
        delegate?.didClickMuteButton()
    }
    
    @IBAction func callButtonClicked(_ sender: Any) {
        delegate?.didClickCallButton()
    }
    
    @IBAction func headerButtonClicked(_ sender: Any) {
        delegate?.didClickHeaderButton()
    }
    
    @IBAction func searchButtonClicked(_ sender: Any) {
        delegate?.didClickSearchButton()
    }
}
