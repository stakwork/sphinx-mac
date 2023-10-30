//
//  NewOnlyTextMessageCollectionViewitem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NewOnlyTextMessageCollectionViewitem: CommonNewMessageCollectionViewitem, ChatCollectionViewItemProtocol {
    
    ///General views
    @IBOutlet weak var bubbleOnlyText: NSBox!
    @IBOutlet weak var receivedArrow: NSView!
    @IBOutlet weak var sentArrow: NSView!
    
    @IBOutlet weak var chatAvatarContainerView: NSView!
    @IBOutlet weak var chatAvatarView: ChatSmallAvatarView!
    @IBOutlet weak var sentMessageMargingView: NSView!
    @IBOutlet weak var receivedMessageMarginView: NSView!
    @IBOutlet weak var statusHeaderViewContainer: NSView!

    @IBOutlet weak var statusHeaderView: StatusHeaderView!
    
    ///Constraints
    @IBOutlet weak var bubbleWidthConstraint: NSLayoutConstraint!
    
    ///Thirs Container
    @IBOutlet weak var textMessageView: NSView!
    @IBOutlet weak var messageLabel: MessageTextField!
    @IBOutlet weak var messageLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!
    
    ///Invoice Lines
    @IBOutlet weak var leftLineContainer: NSBox!
    @IBOutlet weak var rightLineContainer: NSBox!
    
    @IBOutlet weak var sentMessageMenuButton: CustomButton!
    @IBOutlet weak var receivedMessageMenuButton: CustomButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    func releaseMemory() {}
    
    func setupViews() {
        receivedArrow.drawReceivedBubbleArrow(color: NSColor.Sphinx.ReceivedMsgBG)
        sentArrow.drawSentBubbleArrow(color: NSColor.Sphinx.SentMsgBG)
        
        messageLabel.setSelectionColor(color: NSColor.getTextSelectionColor())
        messageLabel.allowsEditingTextAttributes = true
        
        let lineFrame = CGRect(
            x: 0.0,
            y: 0.0,
            width: 3,
            height: view.frame.size.height
        )
        
        let rightLineLayer = rightLineContainer.getVerticalDottedLine(
            color: NSColor.Sphinx.WashedOutReceivedText,
            frame: lineFrame
        )
        rightLineContainer.wantsLayer = true
        rightLineContainer.layer?.addSublayer(rightLineLayer)

        let leftLineLayer = leftLineContainer.getVerticalDottedLine(
            color: NSColor.Sphinx.WashedOutReceivedText,
            frame: lineFrame
        )
        leftLineContainer.wantsLayer = true
        leftLineContainer.layer?.addSublayer(leftLineLayer)
        
        sentMessageMenuButton.cursor = .pointingHand
        receivedMessageMenuButton.cursor = .pointingHand
    }
    
    func configureWith(
        messageCellState: MessageTableCellState,
        mediaData: MessageTableCellState.MediaData?,
        threadOriginalMsgMediaData: MessageTableCellState.MediaData?,
        tribeData: MessageTableCellState.TribeData?,
        linkData: MessageTableCellState.LinkData?,
        botWebViewData: MessageTableCellState.BotWebViewData?,
        uploadProgressData: MessageTableCellState.UploadProgressData?,
        delegate: ChatCollectionViewItemDelegate?,
        searchingTerm: String?,
        indexPath: IndexPath,
        collectionViewWidth: CGFloat
    ) {
        var mutableMessageCellState = messageCellState
        
        guard let bubble = mutableMessageCellState.bubble else {
            return
        }
        
        self.delegate = delegate
        self.rowIndex = indexPath.item
        self.messageId = mutableMessageCellState.messageId
        
        configureWith(statusHeader: mutableMessageCellState.statusHeader)
        
        ///Text message content
        configureWith(
            messageContent: mutableMessageCellState.messageContent,
            searchingTerm: searchingTerm
        )
        
        ///Header and avatar
        configureWith(
            avatarImage: mutableMessageCellState.avatarImage
        )
        configureWith(bubble: bubble)
        
        ///Invoice Lines
        configureWith(invoiceLines: mutableMessageCellState.invoicesLines)
    }

    override func getBubbleView() -> NSBox? {
        return bubbleOnlyText
    }
    
    @IBAction func messageMenuButtonClicked(_ sender: Any) {
        if let button = sender as? NSButton, let messageId = messageId {
            delegate?.shouldShowOptionsFor(messageId: messageId, from: button)
        }
    }
}
