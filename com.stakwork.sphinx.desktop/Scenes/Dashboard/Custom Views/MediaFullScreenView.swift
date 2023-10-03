//
//  MediaFullScreenView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 29/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit
import Carbon.HIToolbox

protocol MediaFullScreenDelegate: AnyObject {
    func willDismissView()
}

class MediaFullScreenView: NSView, LoadableNib {
    
    weak var delegate: MediaFullScreenDelegate?

    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    
    @IBOutlet weak var closeButton: CustomButton!
    @IBOutlet weak var saveButton: CustomButton!
    @IBOutlet weak var mediaImageView: AspectFillNSImageView!
    @IBOutlet weak var gifView: NSView!
    @IBOutlet weak var videoPlayerView: CustomAVPlayerView!
    @IBOutlet weak var fileDescriptionView: NSBox!
    @IBOutlet weak var fileDescriptionLabel: NSTextField!
    @IBOutlet weak var genericFileDescriptionView: NSBox!
    @IBOutlet weak var genericFileNameLabel: NSTextField!
    @IBOutlet weak var genericFileSizeLabel: NSTextField!
    @IBOutlet weak var arrowPrevContainer: NSBox!
    @IBOutlet weak var arrowPrevButton: CustomButton!
    @IBOutlet weak var arrowNextContainer: NSBox!
    @IBOutlet weak var arrowNextButton: CustomButton!
    
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    
    public enum ViewMode: Int {
        case Sending = 0
        case Viewing = 1
    }
    
    public enum NavigateArrow: Int {
        case Previous = 0
        case Next = 1
    }
    
    var currentMode = ViewMode.Sending
    var message: TransactionMessage? = nil
    var url: URL? = nil
    
    var fileData: Data? = nil
    var fileName: String = ""
    var pdfPagesCount = 0
    var pdfCurrentPage = 0
    
    let kViewMargin:CGFloat = 200
    
    var loading = false {
        didSet {
            if loading {
                hideAllElements()
            }
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [])
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        setViewSize(size: dirtyRect.size)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setViewSize()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setViewSize(size: frameRect.size)
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if Int(event.keyCode) == kVK_Escape {
            closeView()
            return true
        }
        return false
    }
    
    override func mouseDown(with event: NSEvent) {
        if currentMode == ViewMode.Viewing {
            closeView()
        }
        return
    }
    
    func setViewSize(size: CGSize? = nil) {
        saveButton.cursor = .pointingHand
        closeButton.cursor = .pointingHand
        arrowPrevButton.cursor = .pointingHand
        arrowNextButton.cursor = .pointingHand
        
        let height = (size?.height ?? self.frame.height) - kViewMargin
        let width = (size?.width ?? self.frame.width) - kViewMargin
        
        if (imageViewHeightConstraint.constant == height && imageViewWidthConstraint.constant == width) || self.url != nil {
            return
        }
        
        imageViewHeightConstraint.constant = height
        imageViewWidthConstraint.constant = width
        mediaImageView.superview?.layoutSubtreeIfNeeded()
        
        saveButton.isHidden = currentMode == ViewMode.Sending
    }
    
    func showWith(message: TransactionMessage) {
        currentMode = ViewMode.Viewing
        setViewSize()
        loading = true
        
        self.message = message
        
        if message.isGiphy() {
            loadGifhy(message: message)
            return
        } else if let url = message.getMediaUrl() {
            if message.isPicture() {
                if let image = MediaLoader.getImageFromCachedUrl(url: url.absoluteString), message.isPicture() {
                    showImage(image: image)
                    return
                }
            }
            if let data = MediaLoader.getMediaDataFromCachedUrl(url: url.absoluteString) {
                showFromData(data: data, message: message)
                return
            }
        }
        
        hideMediaFullScreenView()
    }
    
    func showWith(
        imageURL: URL,
        message: TransactionMessage,
        completion: @escaping ()->()
    ){
        loading = true

        mediaImageView.sd_setImage(with: imageURL, placeholderImage: nil, options: [.highPriority], completed: { image, _, _, _ in
            if let imageSize = image?.size {
                let maxDimension = CGFloat(512 * 1.5)
                var newWidth = imageSize.width
                var newHeight = imageSize.height

                // Check if width exceeds the maximum allowed width
                if newWidth > maxDimension {
                    newWidth = maxDimension
                    // Scale height based on the aspect ratio
                    newHeight = imageSize.height * (maxDimension / imageSize.width)
                }

                // Check if height exceeds the maximum allowed height
                if newHeight > maxDimension {
                    newHeight = maxDimension
                    // Scale width based on the aspect ratio
                    newWidth = imageSize.width * (maxDimension / imageSize.height)
                }
                
                let newSize = CGSize(width: newWidth, height: newHeight)
                self.setViewSize(size: newSize)
            }
            self.url = imageURL
            self.message = message
            self.currentMode = ViewMode.Viewing
            self.saveButton.isHidden = false

            completion()
        })

    }
    
    func showFromData(data: Data, message: TransactionMessage) {
        if message.isGif() {
            showGif(data: data)
        } else if message.isVideo() {
            showVideo(data: data)
        } else if message.isPDF() {
            showPDF(data: data, fileN: message.mediaFileName)
        }
    }
    
    func loadGifhy(message: TransactionMessage?) {
        guard let message = message else {
            return
        }
        DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
            self.loadGiphy(message: message, thumbnail: true)
            self.loadGiphy(message: message, thumbnail: false)
        })
    }
    
    func loadGiphy(message: TransactionMessage, thumbnail: Bool){
        if let url = GiphyHelper.getUrlFrom(message: message.messageContent ?? "", small: thumbnail) {
            GiphyHelper.getGiphyDataFrom(url: url, messageId: message.id, completion: { (data, messageId) in
                if let data = data {
                    self.showGif(data: data)
                }
            })
        }
    }
    
    //Dragging and drop
    func showVideoWith(data: Data, size: CGSize, autoPlay: Bool = true) {
        currentMode = ViewMode.Sending
        setViewSize(size: size)
        loading = true
        
        showVideo(data: data, autoPlay: false)
    }
    
    func showImageWith(image: NSImage, size: CGSize) {
        currentMode = ViewMode.Sending
        setViewSize(size: size)
        loading = true
        
        showImage(image: image)
    }
    
    func showGifWith(data: Data, size: CGSize) {
        currentMode = ViewMode.Sending
        setViewSize(size: size)
        loading = true
        
        showGif(data: data)
    }
    
    func showFileWith(data: Data, size: CGSize, url: URL) {
        currentMode = ViewMode.Sending
        setViewSize(size: size)
        hideAllElements()
        
        fileData = data
        fileName = (url.absoluteString as NSString).lastPathComponent.percentNotEscaped ?? "file.pdf"
        
        showGenericFileDescription()
    }
    
    func showPDFWith(image: NSImage, size: CGSize, data: Data, url: URL) {
        currentMode = ViewMode.Sending
        setViewSize(size: size)
        loading = true
        
        fileData = data
        pdfPagesCount = data.getPDFPagesCount() ?? 0
        fileName = (url.absoluteString as NSString).lastPathComponent.percentNotEscaped ?? "file.pdf"
        
        showPDFPreview()
    }
    
    func showPDFPreview() {
        if let image = fileData?.getPDFImage(ofPage: pdfCurrentPage) {
            showImage(image: image)
        }
        mediaImageView.wantsLayer = true
        mediaImageView.layer?.backgroundColor = NSColor.white.cgColor
        
        toggleNavigateArrows()
        showDescription()
    }
    
    func toggleNavigateArrows() {
        let firstPage = pdfCurrentPage == 0
        let lastPage = pdfCurrentPage == (fileData?.getPDFPagesCount() ?? 0) - 1
        arrowPrevContainer.isHidden = firstPage
        arrowNextContainer.isHidden = lastPage
    }
    
    //Common methods
    func showDescription() {
        if let description = fileData?.getPDFDescription(fileName: fileName, currentPage: pdfCurrentPage + 1) {
            fileDescriptionLabel.stringValue = description
            fileDescriptionView.isHidden = false
        }
    }
    
    func showGenericFileDescription() {
        if let data = fileData {
            genericFileNameLabel.stringValue = fileName.isEmpty ? "file".localized : fileName
            genericFileSizeLabel.stringValue = data.formattedSize
            genericFileDescriptionView.isHidden = false
            loading = false
        }
    }
    
    func showImage(image: NSImage) {
        loading = false
        
        mediaImageView.alphaValue = 1.0
        mediaImageView.gravity = .resizeAspect
        mediaImageView.image = image
    }
    
    func showGif(data: Data) {
        if let animation = data.createGIFAnimation() {
            loading = false
            gifView.alphaValue = 1.0

            gifView.wantsLayer = true
            gifView.layer?.contents = nil
            gifView.layer?.contentsGravity = .resizeAspect
            gifView.layer?.add(animation, forKey: "contents")
        }
    }
    
    func showVideo(data: Data, autoPlay: Bool = true) {
        let playerItem = CachingPlayerItem(data: data, mimeType: "video/mp4", fileExtension: "mp4")
        playerItem.delegate = self
        let player = AVPlayer(playerItem: playerItem)
        videoPlayerView.player = player
        
        if autoPlay {
            videoPlayerView.player?.play()
        }
    }
    
    func showPDF(data: Data, fileN: String?) {
        fileData = data
        pdfPagesCount = data.getPDFPagesCount() ?? 0
        fileName = fileN ?? "file.pdf"
        
        showPDFPreview()
    }
    
    func hideAllElements() {
        resetPlayer()
        
        mediaImageView.image = nil
        gifView.wantsLayer = false
        
        mediaImageView.alphaValue = 0.0
        gifView.alphaValue = 0.0
        videoPlayerView.alphaValue = 0.0
        
        gifView.layer?.removeAllAnimations()
        mediaImageView.image = nil
        
        mediaImageView.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    func resetPlayer() {
        message = nil
        videoPlayerView.player?.pause()
        videoPlayerView.player = nil
    }
    
    func hideMediaFullScreenView() {
        hideAllElements()
        isHidden = true
    }
    
    @IBAction func pageButtonClicked(_ sender: Any) {
        guard let button = sender as? NSButton else {
            return
        }
        switch(button.tag) {
        case NavigateArrow.Previous.rawValue:
            pdfCurrentPage = pdfCurrentPage - 1
            break
        case NavigateArrow.Next.rawValue:
            pdfCurrentPage = pdfCurrentPage + 1
            break
        default:
            break
        }
        showPDFPreview()
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        let itemType = "image".localized
        let successfulllySave = String(format: "item.successfully.saved".localized, itemType)
        let errorSaving = String(format: "error.saving.item".localized, itemType)

        if let url = url, let message = message {
            MediaDownloader.saveImage(
                url: url,
                message: message,
                completion: {
                    NewMessageBubbleHelper().showGenericMessageView(text: successfulllySave, in: self)
                },
                errorCompletion: {
                    NewMessageBubbleHelper().showGenericMessageView(text: errorSaving, in: self)
                }
            )
        } else if let message = message {
            MediaDownloader.shouldSaveFile(
                message: message,
                completion: { (success, alertMessage) in
                    DispatchQueue.main.async {
                        NewMessageBubbleHelper().showGenericMessageView(text: alertMessage, in: self)
                    }
                }
            )
        }
        
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        closeView()
    }
    
    func closeView() {
        gifView.layer?.removeAllAnimations()
        delegate?.willDismissView()
        hideMediaFullScreenView()
    }
}

extension MediaFullScreenView : CachingPlayerItemDelegate {
    func playerItemReadyToPlay(_ playerItem: CachingPlayerItem) {
        loading = false
        videoPlayerView.alphaValue = 1.0
    }
}
