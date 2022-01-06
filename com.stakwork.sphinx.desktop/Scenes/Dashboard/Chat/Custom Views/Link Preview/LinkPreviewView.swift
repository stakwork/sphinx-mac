//
//  LinkPreviewView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 29/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import SDWebImage
import SwiftLinkPreview
import LinkPresentation

class LinkPreviewView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var previewContainer: NSView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet var descriptionLabel: NSTextView!
    @IBOutlet weak var imageView: AspectFillNSImageView!
    @IBOutlet weak var imageViewBack: NSBox!
    @IBOutlet weak var iconImageView: AspectFillNSImageView!
    @IBOutlet weak var loadingContainer: NSView!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var loadingLabel: NSTextField!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewButton: CustomButton!
    
    public static let kViewHeight: CGFloat = 100
    public static let kImageContainerWidth: CGFloat = 90
    
    var loading = false {
        didSet {
            loadingLabel.alphaValue = loading ? 1.0 : 0.0
            previewContainer.alphaValue = loading ? 0.0 : 1.0
            
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [])
        }
    }
    
    var cancellableLP : Cancellable?
    var lpMetadataProvider: NSObject?
    var slp = CustomSwiftLinkPreview.sharedInstance
    
    var message: TransactionMessage? = nil
    var doneCompletion: ((Int) -> ())? = nil

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
        viewButton.cursor = .pointingHand
        
        imageViewBack.wantsLayer = true
        descriptionLabel.font = NSFont(name: "Roboto-Regular", size: 10.0)!
    }
    
    func getLinkURL(link: String) -> String {
        return slp.extractURL(text: link)?.absoluteString ?? ""
    }
    
    func configurePreview(messageRow: TransactionMessageRow, doneCompletion: ((Int) -> ())? = nil) {
        self.message = messageRow.transactionMessage
        self.doneCompletion = doneCompletion
        
        loadingLabel.stringValue = "loading.preview".localized
        loading = true
        cancellableLP?.cancel()
        
        stopLoading()
        let link = messageRow.getMessageLink()
        let linkURLString = getLinkURL(link: link)
        loadPreview(link: linkURLString)
    }
    
    func loadPreview(link: String) {
        if #available(OSX 10.15, *) {
            if let existingMetadata = MetaDataCache.retrieve(urlString: link) {
                previewLoadingSucceed(metadata: existingMetadata, link: link)
            } else {
                loadWithLinkPresentation(link: link)
            }
        }
    }
    
    @available(OSX 10.15, *)
    func loadWithLinkPresentation(link: String) {
        guard let url = URL(string: link) else {
            previewLoadingFailed()
            return
        }

        LPMetadataProvider().startFetchingMetadata(for: url) { metadata, error in
            DispatchQueue.main.async {
                guard let metadata = metadata, error == nil else {
                    self.previewLoadingFailed()
                    return
                }
                MetaDataCache.cache(metadata: metadata, link: link)
                self.previewLoadingSucceed(metadata: metadata, link: link)
            }
        }
    }
    
    @available(OSX 10.15, *)
    func previewLoadingSucceed(metadata: LPLinkMetadata, link: String) {
        let title = URL(string: link)?.domain?.capitalized ?? (metadata.url?.absoluteString ?? "")
        let description = (metadata.title ?? "").withDefaultValue("title.not.available".localized) + "\n\n" + (metadata.url?.absoluteString ?? "")
        
        titleLabel.stringValue = title
        descriptionLabel.string = description
        
        resetImages()
        
        loading = false
        
        metadata.iconProvider?.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { (data, error) in
            if let data = data as? Data, let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    self.setImages(image: image, isIcon: true)
                }
            }
        }
        
        metadata.imageProvider?.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { (data, error) in
            if let data = data as? Data, let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    self.setImages(image: image, isIcon: false)
                }
            }
        }
        
        if let messageId = message?.id {
            doneCompletion?(messageId)
        }
    }
    
    func resetImages() {
        iconImageView.gravity = .resizeAspect
        imageView.gravity = .resizeAspect
        
        imageView.image = nil
        iconImageView.imageWithName = "imageNotAvailable"
    }
    
    func setImages(image: NSImage, isIcon: Bool) {
        if isIcon {
            iconImageView.image = image
            iconImageView.imageName = ""
            if imageView.image == nil { imageView.image = image }
        } else {
            imageView.image = image
            if iconImageView.imageName == "imageNotAvailable" { iconImageView.image = image }
        }
    }
    
    func isCacheEmpty(result: Response) -> Bool {
        return result.title == nil && result.description == nil && result.image == nil && result.images == nil
    }
    
    func handlePreviewImage(mainImage: String?, images: [String]?, icon: String?) {
        var imagesArray: [String] = []
        
        if let images = images {
            for i in images {
                imagesArray.append(i)
            }
        }
        
        if let image = mainImage {
            imagesArray.append(image)
        }
        
        loadPreviewImage(imagesArray: imagesArray, imageView: imageView, index: 0)
        
        if let icon = icon {
            loadPreviewImage(imagesArray: [icon], imageView: iconImageView, index: 0)
        }
    }
    
    func loadPreviewImage(imagesArray: [String], imageView: AspectFillNSImageView, index: Int) {
        if index >= imagesArray.count {
            imageLoadFailed()
            return
        }
        
        let imageURL = imagesArray[index]
        
        if imageURL.contains(".svg") {
            imageViewBack.layer?.backgroundColor = NSColor.Sphinx.Text.cgColor
        } else {
            imageViewBack.layer?.backgroundColor = NSColor.clear.cgColor
        }
        
        if let image = MediaLoader.getImageFromCachedUrl(url: imageURL) {
            self.showImage(image: image, imageView: imageView)
        } else if let nsUrl = URL(string: imageURL), imageURL != "" {
            MediaLoader.asyncLoadImage(imageView: imageView, nsUrl: nsUrl, placeHolderImage: nil, completion: { image in
                MediaLoader.storeImageInCache(img: image, url: imageURL)
                self.showImage(image: image, imageView: imageView)
            }, errorCompletion: { error in
                self.loadPreviewImage(imagesArray: imagesArray, imageView: imageView, index: index + 1)
            })
        } else {
            self.loadPreviewImage(imagesArray: imagesArray, imageView: imageView, index: index + 1)
        }
    }
    
    func showImage(image: NSImage, imageView: AspectFillNSImageView) {
        setImageContainerWidth(width: LinkPreviewView.kImageContainerWidth)
        
        loading = false
        imageView.image = image
    }
    
    func imageLoadFailed() {
        setImageContainerWidth(width: 0)
        
        loading = false
        imageView.gravity = .center
        imageView.image = NSImage(named: "imageNotAvailable")
    }
    
    func setImageContainerWidth(width: CGFloat) {
        imageWidthConstraint.constant = width
        imageViewBack.superview?.layoutSubtreeIfNeeded()
    }

    func previewLoadingFailed() {
        DispatchQueue.main.async {
            self.loading = false
            self.previewContainer.alphaValue = 0.0
            self.loadingLabel.stringValue = "preview.not.available".localized
            self.loadingLabel.alphaValue = 1.0
        }
    }
    
    func stopLoading() {
        cancellableLP?.cancel()
        
        if #available(OSX 10.15, *) {
            (lpMetadataProvider as? LPMetadataProvider)?.cancel()
        }
    }
    
    func addConstraintsTo(bubbleView: NSView, messageRow: TransactionMessageRow) {
        let isIncoming = messageRow.isIncoming()
        let paidReceivedItem = messageRow.shouldShowPaidAttachmentView()
        
        var bottomMargin: CGFloat = 0
        if paidReceivedItem { bottomMargin += PaidAttachmentView.kViewHeight }
        
        let leftMargin = isIncoming ? Constants.kBubbleReceivedArrowMargin : 0
        let rightMargin = isIncoming ? 0 : Constants.kBubbleSentArrowMargin
        
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: -bottomMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: leftMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: bubbleView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: -rightMargin).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: Constants.kLinkPreviewHeight).isActive = true
    }
    
    @IBAction func previewButtonClicked(_ sender: Any) {
        if let link = message?.getMessageContent().stringFirstLink, !link.isEmpty && link.isValidURL {
            if let url = CustomSwiftLinkPreview.sharedInstance.extractURL(text: link) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
