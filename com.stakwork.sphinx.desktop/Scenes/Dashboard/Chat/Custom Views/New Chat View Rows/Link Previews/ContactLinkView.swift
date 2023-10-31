//
//  ContactLinkView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 13/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

class ContactLinkView: NSView, LoadableNib {
    
    weak var delegate: LinkPreviewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var backgroundColorBox: NSBox!
    @IBOutlet weak var addContactImage: NSImageView!
    @IBOutlet weak var contactImageView: AspectFillNSImageView!
    @IBOutlet weak var contactName: NSTextField!
    @IBOutlet weak var contactPubKey: NSTextField!
    @IBOutlet weak var contactPubKeyIcon: NSImageView!
    @IBOutlet weak var addContactButtonContainer: NSView!
    @IBOutlet weak var addContactButtonView: NSBox!
    @IBOutlet weak var containerButton: CustomButton!
    @IBOutlet weak var borderView: NSView!
    
    static let kViewHeightWithButton: CGFloat = 159
    static let kViewHeightWithoutButton: CGFloat = 103
    
    let kNewContactBubbleHeight: CGFloat = 156

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
        containerButton.cursor = .pointingHand
        
        addContactButtonView.wantsLayer = true
        addContactButtonView.layer?.cornerRadius = 3
        
        contactImageView.wantsLayer = true
        contactImageView.gravity = .resizeAspectFill
        contactImageView.rounded = true
        
        borderView.wantsLayer = true
    }
    
    func configureWith(
        contactLink: BubbleMessageLayoutState.ContactLink,
        and bubble: BubbleMessageLayoutState.Bubble,
        delegate: LinkPreviewDelegate?
    ) {
        self.delegate = delegate
        
        configureColors(incoming: bubble.direction.isIncoming())
        
        addContactButtonContainer.isHidden = contactLink.isContact
        backgroundColorBox.fillColor = contactLink.isContact ? NSColor.clear : NSColor.Sphinx.Body
        
        contactPubKey.stringValue = contactLink.pubkey
        contactName.stringValue = contactLink.alias ?? "new.contact".localized
        
        borderView.removeDashBorder()
        
        if contactLink.isContact {
            addContactImage.isHidden = true
            contactImageView.isHidden = false
            loadImage(imageUrl: contactLink.imageUrl)
        } else {
            addContactImage.isHidden = false
            contactImageView.isHidden = true
            addContactImage.image = NSImage(named: "addContactIcon")?.image(withTintColor: NSColor.Sphinx.SecondaryText)
            
            borderView.addDashedBorder(
                color: bubble.direction.isIncoming() ? NSColor.Sphinx.ReceivedMsgBG : NSColor.Sphinx.SentMsgBG,
                size: CGSize(width: contactLink.bubbleWidth, height: kNewContactBubbleHeight),
                radius: 0
            )
        }
    }
    
    func configureColors(incoming: Bool) {
        let color = incoming ? NSColor.Sphinx.SecondaryText : NSColor.Sphinx.SecondaryTextSent
        contactPubKey.textColor = color
        
        if #available(OSX 10.14, *) {
            contactPubKeyIcon.contentTintColor = color
            contactImageView.contentTintColor = color
        }

        let buttonColor = incoming ? NSColor.Sphinx.LinkReceivedButtonColor : NSColor.Sphinx.LinkSentButtonColor
        addContactButtonView.fillColor = buttonColor
    }
    
    func loadImage(imageUrl: String?) {
        contactImageView.sd_cancelCurrentImageLoad()
        
        if let image = imageUrl, let url = URL(string: image) {
            let transformer = SDImageResizingTransformer(
                size: CGSize(
                    width: contactImageView.bounds.size.width * 2,
                    height: contactImageView.bounds.size.height * 2
                ),
                scaleMode: .aspectFill
            )
            
            contactImageView.sd_setImage(
                with: url,
                placeholderImage: NSImage(named: "profileAvatar"),
                options: [.lowPriority],
                context: [.imageTransformer: transformer],
                progress: nil,
                completed: { (image, error, _, _) in
                    self.contactImageView.image = (error == nil) ? image : NSImage(named: "profileAvatar")
                }
            )
        } else {
            contactImageView.image = NSImage(named: "profileAvatar")
        }
    }
    
    @IBAction func addContactButtonClicked(_ sender: Any) {
        delegate?.didTapOnContactButton()
    }
}
