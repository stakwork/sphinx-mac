//
//  CommonChatCollectionViewItem.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 18/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

@objc protocol MessageCellDelegate {
    @objc optional func didTapCancelButton(transactionMessage: TransactionMessage)
    @objc optional func didTapAttachmentCancel(transactionMessage: TransactionMessage)
    @objc optional func shouldReload(item: NSCollectionViewItem)
    
    func didTapPayButton(transactionMessage: TransactionMessage, item: NSCollectionViewItem)
    func didTapAttachmentRow(message: TransactionMessage)
    func didTapAvatarView(message: TransactionMessage)
    func shouldStartCall(link: String, audioOnly: Bool)
    func didTapPayAttachment(transactionMessage: TransactionMessage)
    func shouldShowOptionsFor(message: TransactionMessage, from button: NSButton)
    func shouldScrollTo(message: TransactionMessage)
    func shouldScrollToBottom()
}

class CommonChatCollectionViewItem: NSCollectionViewItem, MessageRowProtocol {
    
    public weak var delegate: MessageCellDelegate?
    public var audioDelegate: AudioCellDelegate?
    
    @IBOutlet weak var headerView: NSView!
    @IBOutlet weak var senderLabel: NSTextField!
    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet weak var chatAvatarView: ChatSmallAvatarView!
    @IBOutlet weak var leftLineContainer: NSView!
    @IBOutlet weak var rightLineContainer: NSView!
    @IBOutlet weak var optionsButton: CustomButton!
    @IBOutlet weak var topMarginConstraint: NSLayoutConstraint!
    
    var boostedAmountView: MessageBoostView? = nil
    var linkPreviewView: LinkPreviewView? = nil
    var contactLinkPreviewView: ContactLinkPreviewView? = nil
    var tribeLinkPreviewView: TribeLinkPreviewView? = nil
    
    var messageRow: TransactionMessageRow?
    var contact: UserContact?
    var chat: Chat?
    
    public static let kMessageFont = NSFont(name: "Roboto-Regular", size: 16.0)!
    public static let kAmountFont = NSFont(name: "Roboto-Bold", size: 16.0)!
    public static let kBoldSmallMessageFont = NSFont(name: "Roboto-Bold", size: 10.0)!

    override func viewDidLoad() {
        super.viewDidLoad()
        optionsButton?.cursor = .pointingHand
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        linkPreviewView?.stopLoading()
        
        delegate = nil
        audioDelegate = nil
        
        messageRow = nil
        contact = nil
        chat = nil
    }
    
    func isDifferentRow(messageId: Int) -> Bool {
        return messageId != self.messageRow?.transactionMessage.id
    }
    
    func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        self.messageRow = messageRow
        self.contact = contact
        self.chat = chat
        
        chatAvatarView?.hideAllElements()
    }
    
    func commonConfigurationForMessages() {
        guard let messageRow = messageRow, let message = messageRow.transactionMessage else {
            return
        }
        
        addLinkPreview()
        addTribeLinkPreview()
        addPubKeyPreview()
        addBostedAmtLabel()
        
        let isPodcastLiveMessage = messageRow.isPodcastLive
        let consecutiveMessages = messageRow.getConsecutiveMessages()
        
        if let headerView = headerView {
            headerView.wantsLayer = true
            headerView.layer?.masksToBounds = false
            
            let shouldRemoveHeader = consecutiveMessages.previousMessage && !message.isFailedOrMediaExpired()
            headerView.isHidden = shouldRemoveHeader
            chatAvatarView?.isHidden = shouldRemoveHeader
            
            let topPading = CommonChatCollectionViewItem.getReplyTopPadding(message: message)
            topMarginConstraint?.constant = (shouldRemoveHeader ? 0 : Constants.kRowHeaderHeight) + topPading
        }
        
        dateLabel.stringValue = (messageRow.date ?? Date()).getStringDate(format: "hh:mm a")
        dateLabel.font = NSFont(name: "Roboto-Regular", size: 10.0)!

        chatAvatarView?.configureFor(message: message, contact: contact, chat: chat, with: self)

        rightLineContainer?.wantsLayer = true
        leftLineContainer?.wantsLayer = true
        
        rightLineContainer?.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        leftLineContainer?.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        if let senderLabel = senderLabel, let chat = chat {
            let isGroup = chat.isGroup()
            senderLabel.isHidden = !isGroup
            senderLabel.stringValue = isGroup ? "\(message.getMessageSenderNickname())   " : ""
            senderLabel.textColor = ChatHelper.getSenderColorFor(message: message)
        }
        
        if isPodcastLiveMessage {
            hideHeaderElements()
        }
    }
    
    func hideHeaderElements() {
        for subview in headerView.subviews {
            subview.isHidden = true
        }
        senderLabel?.isHidden = false
        senderLabel?.backgroundColor = NSColor.clear
        optionsButton?.isHidden = true
    }
    
    func addBostedAmtLabel() {
        func hideBoostedAmtLabel() {
            if let boostedView = boostedAmountView {
                boostedView.removeFromSuperview()
                boostedAmountView = nil
            }
        }
        
        hideBoostedAmtLabel()
        
        guard let bubbleView = getBubbbleView(), let messageRow = messageRow, let message = messageRow.transactionMessage, let reactions = message.reactions, (reactions.totalSats ?? 0) > 0 else {
            return
        }
        
        boostedAmountView = MessageBoostView(frame: NSRect(x: 0, y: 0, width: Constants.kReactionsMinimumWidth, height: Constants.kReactionsViewHeight))
        boostedAmountView?.configure(message: message)
        view.addSubview(boostedAmountView!)
        boostedAmountView?.addConstraintsTo(bubbleView: bubbleView, messageRow: messageRow)
    }
    
    func getBubbbleView() -> NSView? {
        return nil
    }
    
    //Link Previews
    func addLinkPreview() {
        func removeLinkPreviewView() {
            if let linkPreviewV = linkPreviewView {
                linkPreviewV.removeFromSuperview()
                linkPreviewView = nil
            }
        }
        
        if let bubbleView = getBubbbleView(), let messageRow = messageRow, messageRow.shouldLoadLinkPreview() {
            if linkPreviewView == nil {
                linkPreviewView = LinkPreviewView(frame: CGRect(x: 0, y: 0, width: Constants.kLinkBubbleMaxWidth, height: Constants.kLinkPreviewHeight))
                linkPreviewView?.isHidden = true
                view.addSubview(linkPreviewView!)
            }
            
            linkPreviewView?.addConstraintsTo(bubbleView: bubbleView, messageRow: messageRow)
            linkPreviewView?.configurePreview(messageRow: messageRow, doneCompletion: { messageId in
                if (messageId != messageRow.transactionMessage.id) {
                    return
                }
                if messageRow.transactionMessage.linkHasPreview {
                    self.linkPreviewView?.isHidden = false
                    return
                }
                self.reloadRowOnLinkLoadFinished(delay: 1.0)
            })
        } else {
            removeLinkPreviewView()
        }
    }
    
    //Tribe Link Previews
    func addTribeLinkPreview() {
        func removeTribeLinkPreviewView() {
            if let tribeLinkPreviewV = tribeLinkPreviewView {
                tribeLinkPreviewV.removeFromSuperview()
                tribeLinkPreviewView = nil
            }
        }

        if let bubbleView = getBubbbleView(), let messageRow = messageRow, messageRow.shouldLoadTribeLinkPreview() {
            if tribeLinkPreviewView == nil {
                let linkHeight = CommonChatCollectionViewItem.getLinkPreviewHeight(messageRow: messageRow) - Constants.kBubbleBottomMargin
                tribeLinkPreviewView = TribeLinkPreviewView(frame: CGRect(x: 0, y: 0, width: Constants.kLinkBubbleMaxWidth, height: linkHeight))
                tribeLinkPreviewView?.isHidden = true
                view.addSubview(tribeLinkPreviewView!)
            }
            
            if let tribeInfo = messageRow.transactionMessage.tribeInfo {
                tribeLinkPreviewView?.addConstraintsTo(bubbleView: bubbleView, messageRow: messageRow)
                tribeLinkPreviewView?.configureView(messageRow: messageRow, tribeInfo: tribeInfo, delegate: self)
                tribeLinkPreviewView?.isHidden = false
                return
            }

            tribeLinkPreviewView?.configurePreview(messageRow: messageRow, delegate: self, doneCompletion: { messageId in
                if (messageId != messageRow.transactionMessage.id || messageRow.transactionMessage.linkHasPreview) {
                    return
                }
                self.reloadRowOnLinkLoadFinished(delay: 0.5)
            })
        } else {
            removeTribeLinkPreviewView()
        }
    }
    
    //PubKey Previews
    func addPubKeyPreview() {
        func removePubKeyPreviewView() {
            if let contactLinkPreviewV = contactLinkPreviewView {
                contactLinkPreviewV.removeFromSuperview()
                contactLinkPreviewView = nil
            }
        }

        if let bubbleView = getBubbbleView(), let messageRow = messageRow, messageRow.shouldShowPubkeyPreview() {
            messageRow.transactionMessage.linkHasPreview = true
            
            if contactLinkPreviewView == nil {
                let linkHeight = CommonChatCollectionViewItem.getLinkPreviewHeight(messageRow: messageRow) - Constants.kBubbleBottomMargin
                contactLinkPreviewView = ContactLinkPreviewView(frame: NSRect(x: 0, y: 0, width: Constants.kLinkBubbleMaxWidth, height: linkHeight))
                view.addSubview(contactLinkPreviewView!)
            }
            contactLinkPreviewView?.addConstraintsTo(bubbleView: bubbleView, messageRow: messageRow)
            contactLinkPreviewView?.configureView(messageRow: messageRow, delegate: self)
        } else {
            removePubKeyPreviewView()
        }
    }
    
    func reloadRowOnLinkLoadFinished(delay: Double = 0.0) {
        self.messageRow?.transactionMessage.linkHasPreview = true
        
        DelayPerformedHelper.performAfterDelay(seconds: delay, completion: {
            self.delegate?.shouldReload?(item: self)
        })
    }
    
    func addLinksOnLabel(label: NSTextField) {
        label.addLinksOnLabel()
    }
    
    func addRightLine() {
        if let rightLineContainer = rightLineContainer {
            rightLineContainer.wantsLayer = true
            
            let viewFrame = view.frame
            let y: CGFloat = (Int(viewFrame.size.height) % 2 == 0) ? 2 : 1
            let lineFrame = CGRect(x: 0.0, y: y, width: 3, height: viewFrame.size.height - y)
            let lineLayer = getVerticalDottedLine(color: NSColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
            rightLineContainer.layer?.addSublayer(lineLayer)
        }
    }
    
    func addLeftLine() {
        if let leftLineContainer = leftLineContainer {
            leftLineContainer.wantsLayer = true
            
            let viewFrame = view.frame
            let y: CGFloat = (Int(viewFrame.size.height) % 2 == 0) ? 2 : 1
            let lineFrame = CGRect(x: 0.0, y: y, width: 3, height: viewFrame.size.height - y)
            let lineLayer = getVerticalDottedLine(color: NSColor.Sphinx.WashedOutReceivedText, frame: lineFrame)
            leftLineContainer.layer?.addSublayer(lineLayer)
        }
    }
    
    func getVerticalDottedLine(color: NSColor = NSColor.Sphinx.Body, frame: CGRect) -> CAShapeLayer {
        let cgColor = color.cgColor

        let shapeLayer: CAShapeLayer = CAShapeLayer()
        shapeLayer.frame = CGRect(x: frame.origin.x + 0.5, y: frame.origin.y, width: 1.5, height: frame.height)
        shapeLayer.fillColor = cgColor
        shapeLayer.strokeColor = cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.lineDashPattern = [0.01, 5]
        shapeLayer.lineCap = CAShapeLayerLineCap.round

        let path: NSBezierPath = NSBezierPath()
        path.move(to: CGPoint(x: frame.origin.x + 1, y: frame.origin.y))
        path.line(to: CGPoint(x: frame.origin.x + 1, y: frame.origin.y + frame.height))
        shapeLayer.path = path.cgPath

        return shapeLayer
    }
    
    @IBAction func optionsButtonClicked(_ sender: Any) {
        if let button = sender as? NSButton, let message = messageRow?.transactionMessage {
            delegate?.shouldShowOptionsFor(message: message, from: button)
        }
    }
    
    //Reply feature
    static func getReplyTopPadding(message: TransactionMessage) -> CGFloat {
        return message.isReply() ? 50 : 0
    }
    
    static func getMinimumWidth(message: TransactionMessage) -> CGFloat {
        if message.isBoosted() {
            return Constants.kReactionsMinimumWidth
        }
        
        if !message.isPaidAttachment() && !message.isReply() {
            return 0
        }
        
        if message.isIncoming() {
            return Constants.kMinimumReceivedWidth
        } else {
            return Constants.kMinimumSentWidth
        }
    }
    
    public static func applyMinimumWidthTo(size: inout CGSize, minimumWidth: CGFloat) {
        let width = (minimumWidth > size.width) ? minimumWidth : size.width
        size = CGSize(width: width, height: size.height)
    }
    
    public static func applyMinimumWidthTo(width: inout CGFloat, minimumWidth: CGFloat) {
        width = (minimumWidth > width) ? minimumWidth : width
    }
    
    public static func getLinkPreviewHeight(messageRow: TransactionMessageRow) -> CGFloat {
        if messageRow.shouldShowLinkPreview() {
            return Constants.kLinkPreviewHeight
        } else if messageRow.shouldShowTribeLinkPreview() || messageRow.shouldShowPubkeyPreview() {
            if messageRow.isJoinedTribeLink() || messageRow.isExistingContactPubkey().0 {
                return Constants.kTribeLinkPreviewHeight + Constants.kBubbleBottomMargin
            }
            return Constants.kTribeLinkPreviewHeight + Constants.kTribeLinkSeeButtonHeight + Constants.kBubbleBottomMargin
        }
        return 0
    }
    
    public static func getBubbleLinkPreviewHeight(messageRow: TransactionMessageRow) -> CGFloat {
        if messageRow.shouldShowLinkPreview() {
            return Constants.kLinkPreviewHeight
        }
        return 0
    }
}

extension CommonChatCollectionViewItem : LinkPreviewDelegate {
    func didTapOnTribeButton() {
        if let link = messageRow?.getMessageContent().stringFirstTribeLink, link.starts(with: "sphinx.chat://") {
            let userInfo: [String: Any] = ["tribe_link" : link]
            NotificationCenter.default.post(name: .onJoinTribeClick, object: nil, userInfo: userInfo)
        }
    }
    
    func didTapOnContactButton() {
        if let pubKey = messageRow?.getMessageContent().stringFirstPubKey {
            let userInfo: [String: Any] = ["pub-key" : pubKey]
            NotificationCenter.default.post(name: .onPubKeyClick, object: nil, userInfo: userInfo)
        }
    }
}

extension CommonChatCollectionViewItem : ChatSmallAvatarViewDelegate {
    func didClickAvatarView() {
        guard let message = messageRow?.transactionMessage else {
            return
        }
        delegate?.didTapAvatarView(message: message)
    }
}
