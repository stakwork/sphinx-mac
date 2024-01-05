//
//  MessageReplyView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 15/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

@objc protocol SearchTopViewDelegate: AnyObject {
    @objc optional func didCloseReplyView()
    @objc optional func didCloseGiphyView()
    @objc optional func didSelectGiphy(object: GiphyObject, data: Data)
    @objc optional func shouldScrollTo(message: TransactionMessage)
}

class MessageReplyView: NSView, LoadableNib {
    
    weak var delegate: SearchTopViewDelegate?

    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var topLine: NSBox!
    @IBOutlet weak var bottomLine: NSBox!
    
    @IBOutlet weak var senderLabel: NSTextField!
    @IBOutlet weak var senderLabelY: NSLayoutConstraint!
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var leftBar: NSBox!
    @IBOutlet weak var leftBarLeading: NSLayoutConstraint!
    
    @IBOutlet weak var imageContainer: NSView!
    @IBOutlet weak var imageContainerWidth: NSLayoutConstraint!
    @IBOutlet weak var imageView: AspectFillNSImageView!
    @IBOutlet weak var overlay: NSView!
    @IBOutlet weak var overlayIcon: NSTextField!
    
    @IBOutlet weak var closeButtonLabel: NSTextField!
    @IBOutlet weak var closeButton: NSButton!
    @IBOutlet weak var closeButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var rowButton: NSButton!
    
    var message: TransactionMessage? = nil
    var podcastComment: PodcastComment? = nil
    
    static let kMessageReplyHeight: CGFloat = 50
    let kWideContainerWidth: CGFloat = 47
    let kThinContainerWidth: CGFloat = 25
    let kCloseButtonWidth: CGFloat = 45
    
    let kAudioIcon = ""
    let kVideoIcon = ""
    let kFileIcon = "insert_drive_file"
    
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
    
    private func setup() {        
        toggleMediaContainer(show: false, width: 0)
        
        isHidden = true
    }
    
    func resetView() {
        senderLabel.stringValue = ""
        messageLabel.stringValue = ""
        
        imageView.image = nil
        overlay.isHidden = true
        
        senderLabelY.constant = -10
        senderLabel.superview?.layoutSubtreeIfNeeded()
        
        toggleImageContainer(show: false)
    }
    
    func toggleElements(isRow: Bool) {
        topLine.isHidden = isRow
        closeButton.isHidden = isRow
        closeButtonLabel.isHidden = isRow
        closeButtonWidth.constant = isRow ? 0 : kCloseButtonWidth
        rowButton.isHidden = !isRow
        bottomLine.isHidden = !isRow
    }
    
    func configureForRow(with message: TransactionMessage?, and delegate: SearchTopViewDelegate, isIncoming: Bool) {
        self.layer?.backgroundColor = NSColor.clear.cgColor
        configureView(with: message, and: delegate, isRow: true, isIncoming: isIncoming)
    }
    
    func configureForKeyboard(with message: TransactionMessage?, and delegate: SearchTopViewDelegate) {
        self.layer?.backgroundColor = NSColor.Sphinx.HeaderBG.cgColor
        configureView(with: message, and: delegate, isRow: false, isIncoming: false)
    }
    
    func configureForKeyboard(with podcastComment: PodcastComment, and delegate: SearchTopViewDelegate) {
        self.layer?.backgroundColor = NSColor.Sphinx.HeaderBG.cgColor
        
        self.delegate = delegate
        self.podcastComment = podcastComment
        
        resetView()
        
        let (hours, minutes, seconds) = (podcastComment.timestamp ?? 0).getTimeElements()
        let title = podcastComment.title ?? "title.not.available".localized
        let message = "Share audio clip: \(hours):\(minutes):\(seconds)"
        configureWith(title: title, message: message, isIncoming: true)
        
        adjustMargins(isRow: false, isIncoming: false)
        toggleElements(isRow: false)
        
        isHidden = false
    }
    
    func configureView(with message: TransactionMessage?, and delegate: SearchTopViewDelegate, isRow: Bool, isIncoming: Bool) {
        commonConfiguration(message: message, delegate: delegate)
        configureMediaAttachment()
        configureMessage(isIncoming: isIncoming)
        adjustMargins(isRow: isRow, isIncoming: isIncoming)
        toggleElements(isRow: isRow)
        
        isHidden = false
    }
    
    func adjustMargins(isRow: Bool, isIncoming: Bool = false) {
        if isRow {
            leftBarLeading.constant = 10
        } else {
            leftBarLeading.constant = 15
        }
        setMessageLabelMaxWidth(isRow: isRow, isIncoming: isIncoming)
        layoutSubtreeIfNeeded()
    }
    
    func setMessageLabelMaxWidth(isRow: Bool, isIncoming: Bool) {
        if isRow {
            messageLabel.preferredMaxLayoutWidth = frame.width - (messageLabel.frame.origin.x) - (isIncoming ? 0 : Constants.kBubbleSentArrowMargin) - 10
        } else {
            messageLabel.preferredMaxLayoutWidth = frame.width - (messageLabel.frame.origin.x) - kCloseButtonWidth
        }
    }
    
    func commonConfiguration(message: TransactionMessage?, delegate: SearchTopViewDelegate) {
        guard let message = message else {
            return
        }
        
        self.delegate = delegate
        self.message = message
        
        resetView()
    }
    
    func configureMessage(isIncoming: Bool = true) {
        guard let message = self.message else {
            return
        }
        
        leftBar.fillColor = ChatHelper.getSenderColorFor(message: message)
        configureWith(title: message.getMessageSenderNickname(), message: message.getReplyMessageContent(), isIncoming: isIncoming)
    }
    
    func configureWith(title: String, message: String, isIncoming: Bool = true) {
        senderLabel.stringValue = title
        senderLabelY.constant = message.isEmpty ? 0 : -9
        senderLabel.superview?.layoutSubtreeIfNeeded()
        
        bottomLine.fillColor = isIncoming ? NSColor.Sphinx.ReplyDividerReceived : NSColor.Sphinx.ReplyDividerSent
        messageLabel.textColor = isIncoming ? NSColor.Sphinx.WashedOutReceivedText : NSColor.Sphinx.WashedOutSentText
        messageLabel.stringValue = message
    }
    
    func configureMediaAttachment() {
        guard let message = message, message.isMediaAttachment() else {
            return
        }
        
        if message.isAudio() {
            configureAudio()
        } else if message.isVideo() {
            configureVideo()
        } else if message.isGiphy() {
            configureGif()
        } else if message.isPDF() || message.isPicture() {
            configureImage()
        } else {
            configureFile()
        }
    }
    
    func configureFile() {
        imageView.layer?.contents = nil
        toggleOverlay(show: true, color: NSColor.clear, icon: kFileIcon, textColor: NSColor.Sphinx.Text)
        toggleImageContainer(show: true)
    }
    
    func configureGif() {
        guard let message = message else {
            return
        }

        if let url = GiphyHelper.getUrlFrom(message: message.messageContent ?? "") {
            GiphyHelper.getGiphyDataFrom(url: url, messageId: message.id, completion: { (data, messageId) in
                if let data = data {
                    if let animation = data.createGIFAnimation() {
                        self.imageView.wantsLayer = true
                        self.imageView.layer?.contents = nil
                        self.imageView.layer?.contentsGravity = .resizeAspect
                        self.imageView.layer?.add(animation, forKey: "contents")
                        
                        self.toggleImageContainer(show: true)
                        return
                    }
                }
                self.toggleImageContainer(show: false)
            })
            return
        }

        self.toggleImageContainer(show: false)
    }
    
    func configureImage() {
        guard let message = message else {
            return
        }
        
        toggleImageContainer(show: true)
        
        if let url = message.getMediaUrl() {
            MediaLoader.loadImage(url: url, message: message, completion: { messageId, image in
                if messageId != message.id {
                    return
                }
                self.imageView.image = image
            }, errorCompletion: { messageId in
                self.toggleImageContainer(show: false)
            })
        } else {
            toggleImageContainer(show: false)
        }
    }
    
    func configureVideo() {
        guard let message = message else {
            return
        }
        
        toggleVideoContainer(show: true)
        
        if let url = message.getMediaUrl() {
            if let image = MediaLoader.getImageFromCachedUrl(url: url.absoluteString) {
                self.imageView.image = image
                return
            }
        }
        toggleMediaContainer(show: true, width: kThinContainerWidth)
        toggleOverlay(show: true, color: NSColor.clear, icon: kVideoIcon, textColor: NSColor.Sphinx.Body)
    }
    
    func configureAudio() {
        toggleAudioContainer(show: true)
    }
    
    func toggleMediaContainer(show: Bool, width: CGFloat) {
        imageContainerWidth.constant = show ? width : 0
        imageContainer.superview?.layoutSubtreeIfNeeded()
        imageContainer.isHidden = !show
    }
    
    func toggleOverlay(show: Bool, color: NSColor, icon: String, textColor: NSColor) {
        overlay.wantsLayer = true
        overlay.isHidden = false
        overlay.layer?.backgroundColor = color.cgColor
        overlayIcon.stringValue = icon
        overlayIcon.textColor = textColor
    }
    
    func toggleImageContainer(show: Bool) {
        toggleMediaContainer(show: show, width: kWideContainerWidth)
    }
    
    func toggleAudioContainer(show: Bool) {
        toggleMediaContainer(show: show, width: kThinContainerWidth)
        toggleOverlay(show: show, color: NSColor.clear, icon: kAudioIcon, textColor: NSColor.Sphinx.Text)
    }
    
    func toggleVideoContainer(show: Bool) {
        toggleMediaContainer(show: show, width: kWideContainerWidth)
        toggleOverlay(show: show, color: NSColor.black.withAlphaComponent(0.6), icon: kVideoIcon, textColor: NSColor.Sphinx.Body)
    }
    
    func getViewHeight() -> CGFloat {
        return isHidden ? 0 : MessageReplyView.kMessageReplyHeight
    }
    
    func getReplyingMessage() -> TransactionMessage? {
        if let message = message, !isHidden {
            return message
        }
        return nil
    }
    
    func getReplyingPodcast() -> PodcastComment? {
        if let podcastComment = podcastComment, !isHidden {
            return podcastComment
        }
        return nil
    }
    
    func resetObjects() {
        podcastComment = nil
        message = nil
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        resetObjects()
        isHidden = true
        delegate?.didCloseReplyView?()
    }
    
    @IBAction func rowButtonClicked(_ sender: Any) {
        if let message = self.message {
            delegate?.shouldScrollTo?(message: message)
        }
    }
}
