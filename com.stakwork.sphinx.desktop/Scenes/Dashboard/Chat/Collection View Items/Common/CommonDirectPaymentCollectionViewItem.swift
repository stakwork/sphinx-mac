//
//  CommonDirectPaymentCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 01/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonDirectPaymentCollectionViewItem : CommonChatCollectionViewItem {
    
    @IBOutlet weak var bubbleView: PaymentInvoiceBubbleView!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var paymentIcon: NSImageView!
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var unitLabel: NSTextField!
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var pictureBubbleView: PictureBubbleView!
    @IBOutlet weak var separatorLine: NSBox!
    @IBOutlet weak var imageLoadingView: NSBox!
    @IBOutlet weak var imagePreloader: NSImageView!
    @IBOutlet weak var imageNotAvailableContainer: NSView!
    @IBOutlet weak var imageNotAvailable: NSImageView!
    @IBOutlet weak var recipientAvatarView: ChatSmallAvatarView!
    @IBOutlet weak var pictureBubbleViewHeight: NSLayoutConstraint!
    @IBOutlet weak var bubbleViewWidth: NSLayoutConstraint!
    
    static let kLabelSideMargins: CGFloat = 46
    static let kBubbleMaximumWidth: CGFloat = 210
    static let kAmountLabelSideMargins: CGFloat = 100
    static let kLabelTopMargin: CGFloat = 60
    static let kLabelBottomMargin: CGFloat = 20
    static let kRecipientViewWidth: CGFloat = 56
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageLoadingView.fillColor = NSColor.clear
    }
    
    override func viewWillLayout() {
        imagePreloader.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
    }
    
    func configureMessageRow(
        messageRow: TransactionMessageRow,
        contact: UserContact?,
        chat: Chat?,
        incoming: Bool,
        chatWidth: CGFloat
    ) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)

        commonConfigurationForMessages()
    
        let (bubbleWidth, labelWidth) = CommonDirectPaymentCollectionViewItem.getBubbleAndLabelWidth(messageRow: messageRow)
        bubbleViewWidth.constant = bubbleWidth
        bubbleView.superview?.layoutSubtreeIfNeeded()

        let labelHeight = CommonDirectPaymentCollectionViewItem.getLabelHeight(messageRow: messageRow, width: labelWidth)
        let bubbleHeight = labelHeight + CommonDirectPaymentCollectionViewItem.kLabelTopMargin + CommonDirectPaymentCollectionViewItem.kLabelBottomMargin
        let bubbleSize = CGSize(width: bubbleWidth, height: bubbleHeight)
        
        if incoming {
            bubbleView.showIncomingDirectPaymentBubble(messageRow: messageRow, size: bubbleSize, hasImage: messageRow.isPaymentWithImage())
        } else {
            bubbleView.showOutgoingDirectPaymentBubble(messageRow: messageRow, size: bubbleSize, hasImage: messageRow.isPaymentWithImage())
        }
        
        let encrypted = messageRow.encrypted
        lockSign.stringValue = encrypted ? "lock" : ""
        
        configureRecipientInfoWith()
        setAmountAndTextLabels()
        tryLoadingImage()

        if messageRow.shouldShowRightLine {
            addRightLine()
        }

        if messageRow.shouldShowLeftLine {
            addLeftLine()
        }
    }
    
    public static func getBubbleAndLabelWidth(messageRow: TransactionMessageRow) -> (CGFloat, CGFloat) {
        let recipientViewWidth = (messageRow.transactionMessage?.chat?.isPublicGroup() ?? false) ? kRecipientViewWidth : 0
        let amountBubbleWidth = getAmountLabelWidth(messageRow: messageRow) + kAmountLabelSideMargins + recipientViewWidth
        var labelBubbleWidth = getLabelSize(messageRow: messageRow).width + kLabelSideMargins
        if labelBubbleWidth > kBubbleMaximumWidth {
            let labelHeight = getLabelHeight(messageRow: messageRow, width: kBubbleMaximumWidth - kLabelSideMargins)
            labelBubbleWidth = getLabelSize(messageRow: messageRow, width: kBubbleMaximumWidth - kLabelSideMargins, height: labelHeight).width + kLabelSideMargins
        }
        let maxBubbleWidth = max(amountBubbleWidth, labelBubbleWidth)
        let hasImage = messageRow.isPaymentWithImage()
        let bubbleWidth = maxBubbleWidth > kBubbleMaximumWidth || hasImage ? kBubbleMaximumWidth : maxBubbleWidth
        let labelWidth = bubbleWidth - kLabelSideMargins
        
        return (bubbleWidth, labelWidth)
    }
    
    func setAmountAndTextLabels() {
        guard let messageRow = messageRow else {
            return
        }
        
        messageLabel.font = Constants.kMessageFont
        
        let text = messageRow.transactionMessage.messageContent ?? ""
        let amountString = messageRow.getAmountString()
        amountLabel.stringValue = amountString
        messageLabel.stringValue = text
    }
    
    func configureRecipientInfoWith() {
        guard let message = messageRow?.transactionMessage, (self.chat?.isPublicGroup() ?? false) else {
            recipientAvatarView.isHidden = true
            return
        }

        recipientAvatarView.isHidden = false
        
        recipientAvatarView.configureFor(
            alias: message.recipientAlias,
            picture: message.recipientPic
        )
    }
    
    func tryLoadingImage() {
        guard let messageRow = messageRow else {
            return
        }
        
        let hasImage = messageRow.isPaymentWithImage()
        separatorLine.alphaValue = hasImage ? 1.0 : 0.0
        pictureBubbleView.clearBubbleView()
        
        toggleLoadingImage(loading: false)
        imageNotAvailable.alphaValue = 0.0
        
        if hasImage {
            let (bubbleWidth, _) = CommonDirectPaymentCollectionViewItem.getBubbleAndLabelWidth(messageRow: messageRow)
            let imageHeight = CommonDirectPaymentCollectionViewItem.getImageHeight(messageRow: messageRow, bubbleWidth: bubbleWidth)
            let bubbleSize = CGSize(width: bubbleWidth, height: imageHeight)
            
            pictureBubbleViewHeight.constant = imageHeight
            pictureBubbleView.superview?.layoutSubtreeIfNeeded()
            
            loadImageInBubble(messageRow: messageRow, size: bubbleSize, image: nil)
            
            if let url = messageRow.transactionMessage.getTemplateURL() {
                loadImage(url: url, messageRow: messageRow, bubbleSize: bubbleSize)
            } else {
                imageLoadingFailed()
            }
        } else {
            pictureBubbleViewHeight.constant = 0
            pictureBubbleView.superview?.layoutSubtreeIfNeeded()
        }
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
        imageNotAvailable.image = NSImage(named: "imageNotAvailable")
        imageNotAvailableContainer.alphaValue = 1.0
    }
    
    func loadImage(url: URL, messageRow: TransactionMessageRow, bubbleSize: CGSize) {
        toggleLoadingImage(loading: true)

        MediaLoader.loadImage(url: url, message: messageRow.transactionMessage, completion: { messageId, image in
            if self.isDifferentRow(messageId: messageId) { return }
            self.loadImageInBubble(messageRow: messageRow, size: bubbleSize, image: image)
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }
            self.imageLoadingFailed()
        })
    }
    
    func loadImageInBubble(messageRow: TransactionMessageRow, size: CGSize, image: NSImage?) {
        toggleLoadingImage(loading: false)
        let incoming = messageRow.isIncoming()
        
        if incoming {
            pictureBubbleView.showIncomingPictureBubble(messageRow: messageRow, size: size, image: image, contentMode: .resizeAspect)
        } else {
            pictureBubbleView.showOutgoingPictureBubble(messageRow: messageRow, size: size, image: image, contentMode: .resizeAspect)
        }
    }
    
    public static func getLabelHeight(messageRow: TransactionMessageRow, width: CGFloat) -> CGFloat {
        let text = messageRow.transactionMessage.messageContent ?? ""
        let labelHeight = getLabelSize(messageRow: messageRow, width: width).height
        return text.isEmpty ? -17 : labelHeight
    }
    
    static func getAmountLabelAttributes(messageRow: TransactionMessageRow) -> (String, NSColor, NSFont) {
        let font = CommonChatCollectionViewItem.kAmountFont
        let color = NSColor.Sphinx.Text
        let amountString = messageRow.getAmountString()
        return (amountString, color, font)
    }
    
    public static func getLabelSize(messageRow: TransactionMessageRow, width: CGFloat? = nil, height: CGFloat? = nil) -> CGSize {
        let textColorAndFont = messageRow.getMessageAttributes()
        let (_, size) = MessageBubbleView.getLabel(maxWidth: width, height: height, textColorAndFont: textColorAndFont)
        return size
    }
    
    public static func getAmountLabelWidth(messageRow: TransactionMessageRow) -> CGFloat {
        let amountLabelAttributes = getAmountLabelAttributes(messageRow: messageRow)
        let (_, size) = MessageBubbleView.getLabel(textColorAndFont: amountLabelAttributes)
        return size.width
    }
    
    public static func getImageHeight(messageRow: TransactionMessageRow, bubbleWidth: CGFloat) -> CGFloat {
        let hasImage = messageRow.transactionMessage.mediaToken != nil
        let imageRatio = messageRow.transactionMessage.getImageRatio() ?? 1.0
        return hasImage ? bubbleWidth * CGFloat(imageRatio) : 0.0
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let (bubbleWidth, labelWidth) = CommonDirectPaymentCollectionViewItem.getBubbleAndLabelWidth(messageRow: messageRow)
        
        let labelHeight = getLabelHeight(messageRow: messageRow, width: labelWidth)
        let imageHeight = getImageHeight(messageRow: messageRow, bubbleWidth: bubbleWidth)
            
        return labelHeight + imageHeight + kLabelTopMargin + kLabelBottomMargin + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin
    }
}
