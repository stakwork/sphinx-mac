//
//  MessageBoostView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 24/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class MessageBoostView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var boostIconContainer: NSBox!
    @IBOutlet weak var boostIcon: NSImageView!
    @IBOutlet weak var leftMargin: NSLayoutConstraint!
    @IBOutlet weak var rightMargin: NSLayoutConstraint!
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var unitLabel: NSTextField!
    @IBOutlet weak var countLabel: NSTextField!
    @IBOutlet weak var initialsContainer1: NSView!
    @IBOutlet weak var initialsContainer2: NSView!
    @IBOutlet weak var initialsContainer3: NSView!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setup()
    }
    
    func setup() {
        leftMargin.constant = Constants.kLabelMargins
        rightMargin.constant = Constants.kLabelMargins
        layoutSubtreeIfNeeded()
    }
    
    func configure(message: TransactionMessage) {
        configureIncoming(message)
        
        let boosted = message.reactions?.boosted ?? false
        configureBoostIcon(active: boosted || message.isOutgoing())
        
        let amount = message.reactions?.totalSats ?? 0
        amountLabel.stringValue = amount.formattedWithSeparator
        
        let totalUsers = message.reactions?.users.count ?? 0
        countLabel.stringValue = totalUsers > 3 ? " +\(totalUsers - 3)" : ""
        
        showCircles(message)
    }
    
    func configureBoostIcon(active: Bool) {
        boostIconContainer.fillColor = active ? NSColor.Sphinx.PrimaryGreen : NSColor.Sphinx.WashedOutReceivedText
        if #available(OSX 10.14, *) {
            boostIcon.contentTintColor = active ? NSColor.white : NSColor.Sphinx.OldReceivedMsgBG
        }
    }
    
    func configureIncoming(_ message: TransactionMessage) {
        let incoming = message.isIncoming()
        
        unitLabel.textColor = incoming ? NSColor.Sphinx.WashedOutReceivedText : NSColor.Sphinx.WashedOutSentText
        countLabel.textColor = incoming ? NSColor.Sphinx.WashedOutReceivedText : NSColor.Sphinx.WashedOutSentText
        
        let size: CGFloat = incoming ? 11 : 16
        amountLabel.font = NSFont(name: incoming ? "Roboto-Regular" : "Roboto-Medium", size: size)!
        unitLabel.font = NSFont(name: "Roboto-Regular", size: size)!
    }
    
    func showCircles(_ message: TransactionMessage) {
        guard let reactions = message.reactions else {
            return
        }
        let incoming = message.isIncoming()
        let containers = [initialsContainer1, initialsContainer2, initialsContainer3]
        
        var i = 0
        for (name, (color, image)) in reactions.users {
            if i >= 3 { return }
            if let container = containers[i] { showInitialsFor(name, color: color, and: image, in: container, incoming: incoming) }
            i = i + 1
        }
    }
    
    func showInitialsFor(_ name: String, color: NSColor, and imageUrl: String?, in container: NSView, incoming: Bool) {
        container.isHidden = false
        container.wantsLayer = true
        container.layer?.cornerRadius = container.frame.size.height / 2
        
        let backgroundColor = incoming ? NSColor.Sphinx.OldReceivedMsgBG : NSColor.Sphinx.OldSentMsgBG
        container.layer?.backgroundColor = backgroundColor.cgColor
        
        for view in container.subviews {
            if let label = view as? NSTextField {
                label.stringValue = name.getInitialsFromName()
                label.sizeToFit()
            }
            
            if let circle = view as? NSBox {
                circle.fillColor = (imageUrl != nil) ? NSColor.clear : color
            }
            
            if let imageView = view as? AspectFillNSImageView {
                if let imageUrl = imageUrl {
                    if let image = MediaLoader.getImageFromCachedUrl(url: imageUrl) {
                        if let staticData = image.sd_imageData(as: .JPEG, compressionQuality: 1, firstFrameOnly: true) {
                            imageView.image = NSImage(data: staticData)
                        }
                    } else if let url = URL(string: imageUrl) {
                        imageView.sd_setImage(
                            with: url,
                            placeholderImage: NSImage(named: "profile_avatar"),
                            options: [.highPriority, .decodeFirstFrameOnly],
                            progress: nil
                        )
                    }
                }  else {
                    imageView.image = nil
                }
            }
        }
    }
    
    func addConstraintsTo(bubbleView: NSView, messageRow: TransactionMessageRow) {
        let isIncoming = messageRow.isIncoming()
        let hasLinksPreview = (messageRow.shouldShowLinkPreview() ||
                               messageRow.shouldShowTribeLinkPreview() ||
                               messageRow.shouldShowPubkeyPreview()) && messageRow.transactionMessage.linkHasPreview
        let paidReceivedItem = messageRow.shouldShowPaidAttachmentView()
        
        let leftMargin = isIncoming ? Constants.kBubbleReceivedArrowMargin : 0
        let rightMargin = isIncoming ? 0 : Constants.kBubbleSentArrowMargin
        
        let linkPreviewHeight = CommonChatCollectionViewItem.getLinkPreviewHeight(messageRow: messageRow)
        
        var bottomMargin: CGFloat = 0
        if hasLinksPreview { bottomMargin += linkPreviewHeight }
        if paidReceivedItem { bottomMargin += PaidAttachmentView.kViewHeight }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: -bottomMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: leftMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: -rightMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: Constants.kReactionsViewHeight + Constants.kLabelMargins).isActive = true
    }
}
