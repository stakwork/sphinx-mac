//
//  CommonPictureCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonPictureCollectionViewItem : CommonReplyCollectionViewItem {
    
    @IBOutlet weak var bubbleView: PictureBubbleView!
    @IBOutlet weak var messageBubbleView: MessageBubbleView!
    @IBOutlet weak var pictureImageView: NSImageView!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var imageLoadingView: NSBox!
    @IBOutlet weak var imagePreloader: NSImageView!
    @IBOutlet weak var gifOverlayView: GifOverlayView!
    @IBOutlet weak var pictureBubbleWidth: NSLayoutConstraint!
    @IBOutlet weak var pictureBubbleHeight: NSLayoutConstraint!
    @IBOutlet weak var pdfInfoView: PdfInfoView!
    
    static let kPictureMessageMargin: CGFloat = 0.0
    
    var giphyHelper : GiphyHelper?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bubbleView.delegate = self
        gifOverlayView.configure(delegate: self)
        imageLoadingView.fillColor = NSColor.Sphinx.Body.withAlphaComponent(0.5)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        bubbleView.clearData()
    }
    
    override func viewWillLayout() {
        imagePreloader.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
    }
    
    override func getBubbbleView() -> NSView? {
        return messageBubbleView
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        let bubbleHeight = messageRow.transactionMessage.isPDF() ? Constants.kPDFBubbleHeight : Constants.kPictureBubbleHeight
        let ratio = GiphyHelper.getAspectRatioFrom(message: messageRow.transactionMessage.messageContent ?? "")
        pictureBubbleWidth.constant = Constants.kPictureBubbleHeight
        pictureBubbleHeight.constant = bubbleHeight / CGFloat(ratio)
        view.layoutSubtreeIfNeeded()
        
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
    }
    
    func loadImage(url: URL, messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        toggleLoadingImage(loading: true)
        pictureImageView.alphaValue = 0.0
        
        MediaLoader.loadImage(url: url, message: messageRow.transactionMessage, completion: { messageId, image in
            if self.isDifferentRow(messageId: messageId) { return }
            self.loadImageInBubble(messageRow: messageRow, size: bubbleSize, image: image)
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }
            self.imageLoadingFailed()
        })
    }
    
    func loadImageInBubble(messageRow: TransactionMessageRow, size: CGSize, image: NSImage? = nil, gifData: Data? = nil) {
        gifOverlayView.isHidden = !messageRow.transactionMessage.isGif()
        pdfInfoView.isHidden = !messageRow.transactionMessage.isPDF()
        pdfInfoView.configure(message: messageRow.transactionMessage)
    }
    
    func loadGiphy(messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        toggleLoadingImage(loading: true)
        pictureImageView.alphaValue = 0.0
        
        let giphyHelper = getGiphyHelper()
        giphyHelper.loadGiphyDataFrom(message: messageRow.transactionMessage, completion: { data, messageId in
            if self.isDifferentRow(messageId: messageId) { return }

            self.loadImageInBubble(messageRow: messageRow, size: bubbleSize, gifData: data)
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }

            self.imageLoadingFailed()
        })
    }
    
    func getGiphyHelper() -> GiphyHelper {
        if let giphyHelper = self.giphyHelper {
            return giphyHelper
        }
        self.giphyHelper = GiphyHelper()
        return self.giphyHelper!
    }
    
    func toggleLoadingImage(loading: Bool) {
        imageLoadingView.alphaValue = loading ? 1.0 : 0.0
        
        if loading {
            imagePreloader.rotate()
        } else {
            imagePreloader.stopRotating()
        }
    }
    
    func imageLoadingFailed() {
        toggleLoadingImage(loading: false)
        pictureImageView.image = NSImage(named: "imageNotAvailable")
        pictureImageView.alphaValue = 1.0
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false)
        let hasMediaKey = (messageRow?.transactionMessage.hasMediaKey() ?? false)
        let isGiphy = (messageRow?.transactionMessage.isGiphy() ?? false)
        let imageEncrypted = encrypted && (hasMediaKey || isGiphy)
        lockSign.stringValue = imageEncrypted ? "lock" : ""
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        var height: CGFloat = 0.0
        let bubbleHeight = messageRow.transactionMessage.isPDF() ? Constants.kPDFBubbleHeight : Constants.kPictureBubbleHeight
        let payButtonHeight: CGFloat = messageRow.shouldShowPaidAttachmentView() ? PaidAttachmentView.kViewHeight : 0.0
        let replyTopPadding = CommonChatCollectionViewItem.getReplyTopPadding(message: messageRow.transactionMessage)
        let margin = messageRow.isIncoming() ? Constants.kBubbleReceivedArrowMargin : Constants.kBubbleSentArrowMargin
        let ratio = GiphyHelper.getAspectRatioFrom(message: messageRow.transactionMessage.messageContent ?? "")
        let pictureBubbleHeight = bubbleHeight / CGFloat(ratio)
        
        let boostPadding = getReactionsHeight(messageRow: messageRow)
        
        if messageRow.transactionMessage.hasMessageContent() {
            let bubbleSize = MessageBubbleView.getBubbleSizeFrom(messageRow: messageRow, containerViewWidth: bubbleHeight, bubbleMargin: margin)
            height = pictureBubbleHeight + bubbleSize.height + CommonPictureCollectionViewItem.kPictureMessageMargin
        } else {
            height = pictureBubbleHeight + boostPadding
        }
        
        return height + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin + payButtonHeight + replyTopPadding
    }
    
    public static func getReactionsHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let isBoosted = messageRow.isBoosted
        let hasMessage = messageRow.transactionMessage.hasMessageContent()
        
        if !isBoosted {
            return 0
        }
        return Constants.kReactionsViewHeight + (hasMessage ? 0 : Constants.kLabelMargins)
    }
}

extension CommonPictureCollectionViewItem : GifOverlayDelegate {
    func didTapButton() {
        if let url = messageRow?.transactionMessage.getMediaUrl(), let gifData = MediaLoader.getMediaDataFromCachedUrl(url: url.absoluteString) {
            gifOverlayView.isHidden = true
            bubbleView.addAnimatedImageInBubble(data: gifData)
        }
    }
}

extension CommonPictureCollectionViewItem : PictureBubbleDelegate {
    func didTapAttachmentRow() {
        if let message = messageRow?.transactionMessage, message.isAttachmentAvailable() {
            delegate?.didTapAttachmentRow(message: message)
        }
    }
}
