//
//  MessageBoostImageView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

class MessageBoostImageView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!

    @IBOutlet weak var circularBorderView: NSBox!
    @IBOutlet weak var initialsLabel: NSTextField!
    @IBOutlet weak var circularView: NSBox!
    @IBOutlet weak var imageView: AspectFillNSImageView!
    
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
        imageView.wantsLayer = true
        imageView.rounded = true
        imageView.layer?.cornerRadius = imageView.frame.height / 2
    }
    
    func configureWith(
        boost: BubbleMessageLayoutState.Boost,
        and direction: MessageTableCellState.MessageDirection,
        isThreadHeader: Bool = false
    ) {
        
        let bubbleColor = isThreadHeader ? NSColor.Sphinx.NewHeaderBG : ( direction.isOutgoing() ? NSColor.Sphinx.SentMsgBG : NSColor.Sphinx.ReceivedMsgBG )
        circularBorderView.fillColor = bubbleColor

        circularView.fillColor = boost.senderColor ?? NSColor.Sphinx.SecondaryText
        initialsLabel.stringValue = (boost.senderAlias ?? "Unknown").getInitialsFromName()

        imageView.isHidden = true
        imageView.sd_cancelCurrentImageLoad()

        if let senderPic = boost.senderPic, let url = URL(string: senderPic) {

            let transformer = SDImageResizingTransformer(
                size: CGSize(width: imageView.bounds.size.width * 2, height: imageView.bounds.size.height * 2),
                scaleMode: .aspectFill
            )

            imageView.rounded = true
            imageView.sd_setImage(
                with: url,
                placeholderImage: NSImage(named: "profileAvatar"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .progressiveLoad],
                context: [.imageTransformer: transformer],
                progress: nil,
                completed: { (image, error, _, _) in
                    if (error == nil) {
                        self.imageView.isHidden = false
                        self.imageView.image = image
                    }
                }
            )
        }

        self.isHidden = false
    }
    
}
