//
//  CommonVideoCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 29/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonVideoCollectionViewItem : CommonReplyCollectionViewItem {

    @IBOutlet weak var bubbleView: PictureBubbleView!
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var imageLoadingView: NSBox!
    @IBOutlet weak var imagePreloader: NSImageView!
    @IBOutlet weak var playButton: CustomButton!
    @IBOutlet weak var playButtonContainer: NSView!
    @IBOutlet weak var videoNotAvailableContainer: NSView!
    @IBOutlet weak var videoBubbleWidth: NSLayoutConstraint!
    
    var videoData : Data? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageLoadingView.fillColor = NSColor.Sphinx.Body.withAlphaComponent(0.5)
        playButton.cursor = .pointingHand
    }
    
    override func viewWillLayout() {
        imagePreloader.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
    }
    
    override func getBubbbleView() -> NSView? {
        return messageBubbleView
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        videoBubbleWidth.constant = Constants.kPictureBubbleHeight
        bubbleView.superview?.layoutSubtreeIfNeeded()
        
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
    }
    
    func loadVideo(url: URL, messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        toggleLoadingImage(loading: true)

        MediaLoader.loadVideo(url: url, message: messageRow.transactionMessage, completion: { (messageId, data, image) in
            if self.isDifferentRow(messageId: messageId) { return }
            
            self.videoData = data
            if let image = image {
                self.loadImageInBubble(messageRow: messageRow, size: bubbleSize, image: image)
            }
            self.videoReady()
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }
            
            self.videoLoadingFailed()
        })
    }
    
    func loadImageInBubble(messageRow: TransactionMessageRow, size: CGSize, image: NSImage) {}
    
    func toggleLoadingImage(loading: Bool) {
        videoNotAvailableContainer.alphaValue = 0.0
        playButtonContainer.alphaValue = 0.0
        imageLoadingView.alphaValue = loading ? 1.0 : 0.0
        
        if loading {
            imagePreloader.rotate()
        } else {
            imagePreloader.stopRotating()
        }
    }
    
    func videoReady() {
        toggleLoadingImage(loading: false)
        videoNotAvailableContainer.alphaValue = 0.0
        playButtonContainer.alphaValue = 1.0
    }
    
    func videoLoadingFailed() {
        toggleLoadingImage(loading: false)
        videoNotAvailableContainer.alphaValue = 1.0
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false) && (messageRow?.transactionMessage.hasMediaKey() ?? false)
        lockSign.stringValue = encrypted ? "lock" : ""
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        return CommonPictureCollectionViewItem.getRowHeight(messageRow: messageRow)
    }
    
}
