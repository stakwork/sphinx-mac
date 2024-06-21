//
//  LinkPreviewView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

protocol LinkPreviewDelegate: AnyObject {
    func didTapOnTribeButton()
    func didTapOnContactButton()
    func didTapOnWebLinkButton()
}


class NewLinkPreviewView: NSView, LoadableNib {
    
    weak var delegate: LinkPreviewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var iconImageView: AspectFillNSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var pictureImageView: AspectFillNSImageView!
    @IBOutlet weak var linkButton: CustomButton!
    
    @IBOutlet weak var contentStackView: NSStackView!
    @IBOutlet weak var overContainer: NSBox!
    @IBOutlet weak var loadingView: NSView!
    @IBOutlet weak var failedView: NSView!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
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
        linkData: MessageTableCellState.LinkData?,
        delegate: LinkPreviewDelegate?
    ) {
        overContainer.isHidden = true
        contentStackView.isHidden = true
        loadingWheel.stopAnimation(nil)
        
        guard let linkData = linkData else {
            configureLoadingMode()
            return
        }
        
        if linkData.failed {
            configureFailedMode()
            return
        }
        
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
        
        contentStackView.isHidden = false
    }
    
    func configureLoadingMode() {
        loadingWheel.startAnimation(nil)
        overContainer.isHidden = false
        failedView.isHidden = true
        loadingView.isHidden = false
    }
    
    func configureFailedMode() {
        overContainer.isHidden = false
        failedView.isHidden = false
        loadingView.isHidden = true
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
