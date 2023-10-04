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
        
    }
    
    func configureWith(
        boost: BubbleMessageLayoutState.Boost,
        and direction: MessageTableCellState.MessageDirection
    ) {
        let bubbleColor = direction.isOutgoing() ? NSColor.Sphinx.SentMsgBG : NSColor.Sphinx.ReceivedMsgBG
        circularBorderView.fillColor = bubbleColor

        circularView.fillColor = boost.senderColor ?? NSColor.Sphinx.SecondaryText
        initialsLabel.stringValue = (boost.senderAlias ?? "Unknown").getInitialsFromName()

        imageView.isHidden = true
        imageView.sd_cancelCurrentImageLoad()

        if let senderPic = boost.senderPic, let url = URL(string: senderPic) {

            let transformer = SDImageResizingTransformer(
                size: imageView.bounds.size,
                scaleMode: .aspectFill
            )

            imageView.rounded = true
            imageView.sd_setImage(
                with: url,
                placeholderImage: NSImage(named: "profile_avatar"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .lowPriority],
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
