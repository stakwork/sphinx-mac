//
//  NewChatAttachmentListItem.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 13/06/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit
import Carbon.HIToolbox

protocol NewChatAttachmentDelegate: AnyObject {
    func closePreview(at index: Int?)
    func playPreview(of data: Data?)
}
class NewChatAttachmentListItem: NSCollectionViewItem {

    @IBOutlet weak var contentView: NSView!
    
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var mediaImageView: AspectFillNSImageView!
    @IBOutlet weak var gifView: NSView!
    @IBOutlet weak var videoPlayerView: CustomAVPlayerView!
    
    @IBOutlet weak var fileDescriptionView: NSBox!
    @IBOutlet weak var fileDescriptionLabel: NSTextField!
    @IBOutlet weak var genericFileDescriptionView: NSBox!
    @IBOutlet weak var genericFileNameLabel: NSTextField!
    @IBOutlet weak var genericFileSizeLabel: NSTextField!
    
    public enum ViewMode: Int {
        case Sending = 0
        case Viewing = 1
    }
    
    var previewItem: NewAttachmentItem?
    var currentIndex: Int?
    
    var delegate: NewChatAttachmentDelegate?
    
    var currentMode = ViewMode.Sending
    
    var fileData: Data? = nil
    var fileName: String = ""
    var pdfPagesCount = 0
    var pdfCurrentPage = 0
    
    var loading = false {
        didSet {
            if loading {
                hideAllElements()
            }
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.Sphinx.Text, controls: [])
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.wantsLayer = true
        self.view.layer?.masksToBounds = false
    }
    
    func resetViews() {
        mediaImageView.isHidden = true
        gifView.isHidden = true
        videoPlayerView.isHidden = true
        fileDescriptionView.isHidden = true
        fileDescriptionLabel.isHidden = true
        genericFileDescriptionView.isHidden = true
        genericFileNameLabel.isHidden = true
        genericFileSizeLabel.isHidden = true
    }
    
    func render(with item: NewAttachmentItem, previewImageDelegate: MediaFullScreenDelegate? = nil) {
        self.previewItem = item
        resetViews()
        guard let data = item.previewData else { return }
        if (item.previewType == .image) {
            addImagePreviewView()
            mediaImageView.isHidden = false
        } else if (item.previewType == .gif) {
            showGifWith(data: data, size: CGSize(width: 140, height: 140))
            gifView.isHidden = false
        } else if item.previewType == .video {
            videoPlayerView.isHidden = false
            videoPlayerView.wantsLayer = true
            videoPlayerView.layer?.cornerRadius = 10
            showVideoWith(data: data, size: CGSize(width: 140, height: 140), autoPlay: false)
        } else if item.previewType == .pdf {
            guard let url = item.previewURL else { return }
            
            fileDescriptionView.isHidden = false
            fileDescriptionLabel.isHidden = false
            mediaImageView.isHidden = false
            showPDFWith(image: item.previewImage, size: CGSize(width: 140, height: 140), data: data, url: url)
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
        showDescription()
        showPDFPreview()
    }
    
    func showPDFPreview() {
        if let image = fileData?.getPDFImage(ofPage: pdfCurrentPage) {
            showImage(image: image)
        }
        mediaImageView.wantsLayer = true
        mediaImageView.layer?.backgroundColor = NSColor.white.cgColor
        videoPlayerView.isHidden = true
        showDescription()
    }
    
    func setViewSize(size: CGSize? = nil) {
        mediaImageView.superview?.layoutSubtreeIfNeeded()
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
        mediaImageView.gravity = .resizeAspectFill
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
        videoPlayerView.isHidden = false
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
        videoPlayerView.player?.pause()
        videoPlayerView.player = nil
    }
    
    func hideMediaFullScreenView() {
        hideAllElements()
    }
    
    @IBAction func closePreviewTapped(_ sender: NSButton) {
        delegate?.closePreview(at: currentIndex)
    }
    
    @IBAction func playPreviewTapped(_ sender: NSButton) {
        delegate?.playPreview(of: previewItem?.previewData)
    }
    
    func addImagePreviewView() {
        if let image = previewItem?.previewImage {
            showImageWith(image: image, size: CGSize(width: 140, height: 140))
        }
    }
    
}

extension NewChatAttachmentListItem : CachingPlayerItemDelegate {
    func playerItemReadyToPlay(_ playerItem: CachingPlayerItem) {
        loading = false
        videoPlayerView.alphaValue = 1.0
    }
}
