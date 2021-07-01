//
//  ContactLinkPreviewView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 15/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class ContactLinkPreviewView: LinkPreviewBubbleView, LoadableNib {
    
    weak var delegate: LinkPreviewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var contactImageView: NSImageView!
    @IBOutlet weak var contactName: NSTextField!
    @IBOutlet weak var contactPubkey: NSTextField!
    @IBOutlet weak var contactPubkeyIcon: NSImageView!
    @IBOutlet weak var addContactButtonContainer: NSBox!
    @IBOutlet weak var containerButton: CustomButton!

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
    
    private func setup() {
        containerButton.cursor = .pointingHand
        contactImageView.layer?.cornerRadius = contactImageView.frame.height / 2
    }
    
    func configureView(messageRow: TransactionMessageRow, delegate: LinkPreviewDelegate) {
        self.delegate = delegate
        
        configureColors(messageRow: messageRow)
        addBubble(messageRow: messageRow)
        
        let (existing, contact) = messageRow.isExistingContactPubkey()
        addContactButtonContainer?.isHidden = existing
        contactName.stringValue = contact?.getUserName() ?? "new.contact".localized
        contactPubkey.stringValue = messageRow.getMessageContent().stringFirstPubKey

        loadImage(contact: contact)
    }
    
    func configureColors(messageRow: TransactionMessageRow) {
        let incoming = messageRow.isIncoming()
        let color = incoming ? NSColor.Sphinx.SecondaryText : NSColor.Sphinx.SecondaryTextSent
        contactPubkey.textColor = color
        
        if #available(OSX 10.14, *) {
            contactPubkeyIcon.contentTintColor = color
            contactImageView.contentTintColor = color
        }

        let buttonColor = incoming ? NSColor.Sphinx.LinkReceivedButtonColor : NSColor.Sphinx.LinkSentButtonColor
        addContactButtonContainer.fillColor = buttonColor
    }
    
    func loadImage(contact: UserContact?) {
        let placeHolderImage = NSImage(named: "addContactIcon")?.image(withTintColor: NSColor.Sphinx.SecondaryText)
        
        guard let contact = contact, let imageUrlString = contact.getPhotoUrl()?.removeDuplicatedProtocol(), let imageUrl = URL(string: imageUrlString) else {
            self.contactImageView.image = placeHolderImage
            return
        }
        MediaLoader.asyncLoadImage(imageView: contactImageView, nsUrl: imageUrl, placeHolderImage: placeHolderImage, completion: { image in
            MediaLoader.storeImageInCache(img: image, url: imageUrlString)
            self.contactImageView.image = image
        }, errorCompletion: { _ in })
        
    }
    
    func addBubble(messageRow: TransactionMessageRow) {
        let width = getViewWidth(messageRow: messageRow)
        let height = CommonChatCollectionViewItem.getLinkPreviewHeight(messageRow: messageRow) - Constants.kBubbleBottomMargin
        let bubbleSize = CGSize(width: width, height: height)
        
        let consecutiveBubble = MessageBubbleView.ConsecutiveBubbles(previousBubble: true, nextBubble: false)
        let existingObject = messageRow.isExistingContactPubkey().0

        if messageRow.isIncoming() {
            self.showIncomingLinkBubble(messageRow: messageRow, size: bubbleSize, consecutiveBubble: consecutiveBubble, bubbleMargin: 0, existingObject: existingObject)
        } else {
            self.showOutgoingLinkBubble(messageRow: messageRow, size: bubbleSize, consecutiveBubble: consecutiveBubble, bubbleMargin: 0, xPosition: 0, existingObject: existingObject)
        }
    }
    
    override func addConstraintsTo(bubbleView: NSView, messageRow: TransactionMessageRow) {
        super.addConstraintsTo(bubbleView: bubbleView, messageRow: messageRow)
        addConstraints()
    }
    
    @IBAction func addContactButtonClicked(_ sender: Any) {
        delegate?.didTapOnContactButton()
    }
}
