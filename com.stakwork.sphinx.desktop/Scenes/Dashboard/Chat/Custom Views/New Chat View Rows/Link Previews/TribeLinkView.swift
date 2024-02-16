//
//  TribeLinkView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 14/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

class TribeLinkView: NSView, LoadableNib {

    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var backgroundColorBox: NSBox!
    @IBOutlet weak var borderView: NSView!
    @IBOutlet weak var containerButton: CustomButton!
    @IBOutlet weak var tribeImageView: AspectFillNSImageView!
    @IBOutlet weak var tribePlaceholderImageView: NSImageView!
    @IBOutlet weak var tribeNameLabel: NSTextField!
    @IBOutlet weak var tribeDescriptionLabel: NSTextField!
    @IBOutlet weak var tribeButtonContainer: NSView!
    @IBOutlet weak var tribeButtonView: NSBox!
    
    weak var delegate: LinkPreviewDelegate?
    
    static let kViewHeightWithButton: CGFloat = 171
    static let kViewHeightWithoutButton: CGFloat = 115
    
    let kNewContactBubbleHeight: CGFloat = 168

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
        
        tribeButtonView.wantsLayer = true
        tribeButtonView.layer?.cornerRadius = 3
        
        tribeImageView.wantsLayer = true
        tribeImageView.gravity = .resizeAspectFill
        tribeImageView.radius = 40
        tribeImageView.rounded = true
        tribeImageView.clipsToBounds = true
        
        borderView.wantsLayer = true
    }
    
    func configureWith(
        tribeData: MessageTableCellState.TribeData,
        and bubble: BubbleMessageLayoutState.Bubble,
        delegate: LinkPreviewDelegate?
    ) {
        self.delegate = delegate
        
        configureColors(incoming: bubble.direction.isIncoming())
        
        tribeButtonContainer.isHidden = !tribeData.showJoinButton
        backgroundColorBox.fillColor = tribeData.showJoinButton ? NSColor.Sphinx.Body : NSColor.clear
        
        tribeNameLabel.stringValue = tribeData.name
        tribeDescriptionLabel.stringValue = tribeData.description

        loadImage(
            imageUrl: tribeData.imageUrl,
            rounded: !tribeData.showJoinButton
        )
        
        borderView.removeDashBorder()
        
        if tribeData.showJoinButton {
            borderView.addDashedBorder(
                color: bubble.direction.isIncoming() ? NSColor.Sphinx.ReceivedMsgBG : NSColor.Sphinx.SentMsgBG,
                size: CGSize(width: tribeData.bubbleWidth, height: kNewContactBubbleHeight),
                radius: 0
            )
        }
    }
    
    func configureColors(incoming: Bool) {
        let color = incoming ? NSColor.Sphinx.SecondaryText : NSColor.Sphinx.SecondaryTextSent
        tribeDescriptionLabel.textColor = color
        
        tribeImageView.borderColor = color.cgColor
        tribeImageView.bordered = true
        tribeImageView.contentTintColor = color
        
        let buttonColor = incoming ? NSColor.Sphinx.LinkReceivedButtonColor : NSColor.Sphinx.LinkSentButtonColor
        tribeButtonView.fillColor = buttonColor
    }
    
    func loadImage(
        imageUrl: String?,
        rounded: Bool
    ) {
        tribePlaceholderImageView.isHidden = false
        
        tribeImageView.radius = rounded ? 40 : 8
        tribeImageView.sd_cancelCurrentImageLoad()
        
        if let image = imageUrl, let url = URL(string: image) {
            let transformer = SDImageResizingTransformer(
                size: CGSize(
                    width: tribeImageView.bounds.size.width * 2,
                    height: tribeImageView.bounds.size.height * 2
                ),
                scaleMode: .aspectFill
            )
            
            tribeImageView.sd_setImage(
                with: url,
                placeholderImage: NSImage(named: "tribePlaceholder"),
                options: [.lowPriority, .progressiveLoad],
                context: [.imageTransformer: transformer],
                progress: nil,
                completed: { (image, error, _, _) in
                    if error == nil {
                        self.tribeImageView.image = image
                        self.tribePlaceholderImageView.isHidden = true
                    } else {
                        self.tribePlaceholderImageView.isHidden = false
                    }
                }
            )
        } else {
            tribeImageView.image = nil
            tribeImageView.radius = 8
            
            tribePlaceholderImageView.image = NSImage(named: "tribePlaceholder")
            tribePlaceholderImageView.isHidden = false
        }
    }
    
    @IBAction func tribeButtonClicked(_ sender: Any) {
        delegate?.didTapOnTribeButton()
    }
}
