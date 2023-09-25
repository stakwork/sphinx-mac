//
//  DraggingDestinationView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 03/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol DraggingViewDelegate: AnyObject {
    func imageDragged(image: NSImage)
}

class DraggingDestinationView: NSView, LoadableNib {
    
    weak var delegate: DraggingViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var draggingContainer: NSView!
    @IBOutlet weak var dragLabel: NSTextField!
    
    @IBOutlet weak var topMargin: NSLayoutConstraint!
    @IBOutlet weak var leftMargin: NSLayoutConstraint!
    @IBOutlet weak var bottomMargin: NSLayoutConstraint!
    @IBOutlet weak var rightMargin: NSLayoutConstraint!
    
    var imagePreview: MediaFullScreenView? = nil
    
    var image : NSImage? = nil
    var mediaData : Data? = nil
    var fileName : String? = nil
    var borderColor = NSColor.Sphinx.LightDivider
    var giphyObject : GiphyObject? = nil
    
    var mediaType : AttachmentsManager.AttachmentType? = nil
    
    var acceptableTypes: [NSPasteboard.PasteboardType] { return [ NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileContents] }
    var filteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes: []]
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        let optionsArray = [String]()
        configureFilteringOptions(types: optionsArray)
    }
    
    func configureFilteringOptions(types: [String]) {
        filteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes: types]
    }
    
    func configureForProfilePicture() {
        configureFilteringOptions(types: NSImage.imageTypes)
        dragLabel.stringValue = "drag.image".localized
        dragLabel.font = NSFont(name: "Roboto-Medium", size: 8)!
    }
    
    func configureForTribeImage() {
        configureFilteringOptions(types: NSImage.imageTypes)
        dragLabel.stringValue = "drag.image".localized
        dragLabel.font = NSFont(name: "Roboto-Medium", size: 8)!
        
        topMargin.constant = 0
        bottomMargin.constant = 0
        rightMargin.constant = 0
        leftMargin.constant = 0
        
        self.layoutSubtreeIfNeeded()
    }
    
    func configureForSignup() {
        borderColor = NSColor.clear
        configureFilteringOptions(types: NSImage.imageTypes)
        dragLabel.stringValue = ""
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if isReceivingDrag {
            resetView()
            configureDraggingStyle()
        }
    }
    
    var isReceivingDrag = false {
        didSet {
            needsDisplay = true
        }
    }
    
    func setup() {
        reset()
        resetView()
        
        registerForDraggedTypes(acceptableTypes)
    }
    
    func reset() {
        image = nil
        mediaData = nil
        mediaType = nil
        giphyObject = nil
    }
    
    func addImagePreviewView() {
        imagePreview = MediaFullScreenView()
        
        if let imagePreview = imagePreview {
            contentView.addSubview(imagePreview)
            
            imagePreview.delegate = self
            imagePreview.constraintTo(view: contentView)
        }
    }
    
    func resetView() {
        layer?.backgroundColor = NSColor.clear.cgColor
        draggingContainer.isHidden = true
        
        if let imagePreview = imagePreview {
            imagePreview.removeFromSuperview()
            self.imagePreview = nil
        }
        
        reset()
    }
    
    func isSendingMedia() -> Bool {
        return mediaData != nil && giphyObject == nil
    }
    
    func isSendingGiphy() -> (Bool, GiphyObject?) {
        return (giphyObject != nil, giphyObject)
    }
    
    func getData(price: Int, text: String) -> AttachmentObject? {
        if let data = mediaData, let type = mediaType {
            let (key, encryptedData) = SymmetricEncryptionManager.sharedInstance.encryptData(data: data)
            if let encryptedData = encryptedData {
                let attachmentObject = AttachmentObject(data: encryptedData, fileName: fileName, mediaKey: key, type: type, text: text, image: image, price: price)
                return attachmentObject
            }
        }
        return nil
    }
    
    func getMediaData() -> Data? {
        return mediaData
    }
    
    func configureDraggingStyle() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.Sphinx.Body.withAlphaComponent(0.95).cgColor
        
        draggingContainer.wantsLayer = true
        draggingContainer.addDashedBorder(color: borderColor, size: draggingContainer.bounds.size, lineWidth: 5)
        draggingContainer.layer?.cornerRadius = 10
        draggingContainer.isHidden = false
    }
    
    func showImagePreview(data: Data, image: NSImage) {
        resetView()
        setData(data, image: image)
        mediaType = .Photo
        
        if let delegate = delegate, let _ = self.mediaData, let image = self.image {
            delegate.imageDragged(image: image)
        } else {
            addImagePreviewView()
            imagePreview?.showImageWith(image: image, size: self.frame.size)
            imagePreview?.isHidden = false
        }
    }
    
    func showPDFPreview(data: Data, image: NSImage, url: URL) {
        resetView()
        setData(data, image: image)
        mediaType = .PDF
        
        addImagePreviewView()
        imagePreview?.showPDFWith(image: image, size: self.frame.size, data: data, url: url)
        imagePreview?.isHidden = false
    }
    
    func showGIFPreview(data: Data, image: NSImage?) {
        resetView()
        setData(data, image: image)
        mediaType = .Gif
        
        addImagePreviewView()
        imagePreview?.showGifWith(data: data, size: self.frame.size)
        imagePreview?.isHidden = false
    }
    
    func showVideoPreview(data: Data, url: URL) {
        resetView()
        setData(data, image: nil)
        mediaType = .Video
        
        addImagePreviewView()
        imagePreview?.showVideoWith(data: data, size: self.frame.size, autoPlay: false)
        imagePreview?.isHidden = false
        
        MediaLoader.getThumbnailImageFromVideoData(data: data, videoUrl: url.absoluteString, completion: { image in
            self.setData(data, image: image)
        })
    }
    
    func showFilePreview(data: Data, url: URL) {
        resetView()
        setData(data, image: nil)
        mediaType = .GenericFile
        
        addImagePreviewView()
        imagePreview?.showFileWith(data: data, size: self.frame.size, url: url)
        imagePreview?.isHidden = false
    }
    
    func showGiphyPreview(data: Data, object: GiphyObject) {
        resetView()
        setData(data, image: image, giphyObject: object)
        mediaType = .Gif
        
        addImagePreviewView()
        imagePreview?.showGifWith(data: data, size: self.frame.size)
        imagePreview?.isHidden = false
        MediaLoader.storeMediaDataInCache(data: data, url: GiphyHelper.getSearchURL(url: object.url))
        
        let smallUrl = GiphyHelper.get200WidthURL(url: object.url)
        GiphyHelper.getGiphyDataFrom(url: smallUrl, messageId: 0, cache: false, completion: { (data, messageId) in
            if let data = data {
                MediaLoader.storeMediaDataInCache(data: data, url: smallUrl)
                self.imagePreview?.showGifWith(data: data, size: self.frame.size)
            }
        })
        
        GiphyHelper.getGiphyDataFrom(url: object.url, messageId: 0, cache: false, completion: { (data, messageId) in
            if let data = data {
                MediaLoader.storeMediaDataInCache(data: data, url: object.url)
                self.imagePreview?.showGifWith(data: data, size: self.frame.size)
            }
        })
    }
    
    func setData(_ data: Data, image: NSImage?, giphyObject: GiphyObject? = nil) {
        self.image = image
        self.mediaData = data
        self.giphyObject = giphyObject
    }
    
    func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
        var shouldAccept = false
        let pasteBoard = draggingInfo.draggingPasteboard

        let filteringOptionsCount = filteringOptions[NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes]?.count ?? 0
        let options = filteringOptionsCount > 0 ? filteringOptions : nil
        
        if pasteBoard.canReadObject(forClasses: [NSURL.self], options: options) {
            shouldAccept = true
        }
        return shouldAccept
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        reset()
        
        let allow = shouldAllowDrag(sender)
        isReceivingDrag = allow
        return allow ? .copy : NSDragOperation()
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isReceivingDrag = false
        resetView()
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let allow = shouldAllowDrag(sender)
        return allow
    }
    
    override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
        isReceivingDrag = false
        let pasteBoard = draggingInfo.draggingPasteboard
        
        let urlResult = processURLs(pasteBoard: pasteBoard)
        if(urlResult == true){
            return true
        }
        
        resetView()
        return false
    }
    
    func performPasteOperation(pasteBoard:NSPasteboard)->Bool{
        isReceivingDrag = false
        
        let urlResult = processURLs(pasteBoard: pasteBoard)
        if (urlResult == true) {
            return true
        }
        
        return false
    }
    
    func processURLs(pasteBoard:NSPasteboard) -> Bool{
        let filteringOptionsCount = filteringOptions[NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes]?.count ?? 0
        let options = filteringOptionsCount > 0 ? filteringOptions : nil

        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: options) as? [URL], urls.count == 1 {
            let url = urls[0]
            
            if !url.absoluteString.starts(with: "file://") {
                return false
            }
            
            if let data = getDataFrom(url: url) {
                fileName = (url.absoluteString as NSString).lastPathComponent.percentNotEscaped
                
                if let image = NSImage(contentsOf: url) {
                    if url.isPDF {
                        showPDFPreview(data: data, image: image, url: url)
                    } else if data.isAnimatedImage() {
                        showGIFPreview(data: data, image: image)
                    } else {
                        showImagePreview(data: data, image: image)
                    }
                } else if url.isVideo {
                    showVideoPreview(data: data, url: url)
                } else {
                    showFilePreview(data: data, url: url)
                }
                return true
            }
        }
        if let images = pasteBoard.readObjects(forClasses: [NSImage.self]),
            images.count > 0,
            let image = images[0] as? NSImage,
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            if let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:]) {
                showImagePreview(data: jpegData, image: image)
                return true
            }
        }
        return false
    }
    
    func getDataFrom(url: URL) -> Data? {
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            return nil
        }
    }
}

extension DraggingDestinationView : MediaFullScreenDelegate {
    func willDismissView() {
        resetView()
    }
}
