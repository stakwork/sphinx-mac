//
//  LinkPreviewView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

class NewLinkPreviewView: NSView, LoadableNib {
    
    weak var delegate: LinkPreviewDelegate?
    
    @IBOutlet weak var iconImageView: AspectFillNSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var pictureImageView: AspectFillNSImageView!
    @IBOutlet weak var linkButton: CustomButton!
    
    @IBOutlet var contentView: NSView!
    
    static let kViewHeight: CGFloat = 100.0

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
        linkButton.cursor = .pointingHand
    }
    
    func configureWith(
        linkData: MessageTableCellState.LinkData,
        delegate: LinkPreviewDelegate?
    ) {
        self.delegate = delegate
        
        loadImageOn(
            imageView: iconImageView,
            urlString: linkData.icon ?? linkData.image
        )
        
        loadImageOn(
            imageView: pictureImageView,
            urlString: linkData.image ?? linkData.icon
        )
        
        titleLabel.stringValue = linkData.title
        descriptionLabel.stringValue = linkData.description
    }
    
    func loadImageOn(
        imageView: AspectFillNSImageView,
        urlString: String?
    ) {
        imageView.sd_cancelCurrentImageLoad()
        imageView.gravity = .resizeAspect
        
        if let urlString = urlString, let url = URL(string: urlString) {

            imageView.sd_setImage(
                with: url,
                placeholderImage: NSImage(named: "imageNotAvailable"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .lowPriority],
                progress: nil,
                completed: { (image, error, _, _) in
                    imageView.image = (error == nil) ? image : NSImage(named: "imageNotAvailable")
                }
            )
        } else {
            imageView.image = NSImage(named: "imageNotAvailable")
        }
    }
    
    @IBAction func didClickLinkPreview(_ sender: Any) {
        delegate?.didTapOnWebLinkButton()
    }
}
