//
//  TribeLinkPreviewView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 15/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol LinkPreviewDelegate: AnyObject {
    func didTapOnTribeButton()
    func didTapOnContactButton()
}

class TribeLinkPreviewView: LinkPreviewBubbleView, LoadableNib {
    
    weak var delegate: LinkPreviewDelegate?
    
    @IBOutlet var contentView: NSView!

    @IBOutlet weak var tribeImageView: AspectFillNSImageView!
    @IBOutlet weak var tribeNameLabel: NSTextField!
    @IBOutlet weak var tribeDescriptionLabel: NSTextField!
    @IBOutlet weak var tribeButtonContainer: NSBox!
    @IBOutlet weak var containerButton: CustomButton!
    
    var messageId: Int = -1

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
        containerButton.cursor = .pointingHand
        tribeImageView.wantsLayer = true
        tribeImageView.layer?.borderWidth = 1
        tribeImageView.layer?.borderColor = NSColor.Sphinx.SecondaryText.withAlphaComponent(0.5).cgColor
    }
    
    func configurePreview(messageRow: TransactionMessageRow, delegate: LinkPreviewDelegate, doneCompletion: @escaping (Int) -> ()) {
        messageId = messageRow.transactionMessage.id
        
        let link = messageRow.getMessageContent().stringFirstTribeLink
        loadTribeDetails(link: link, completion: { tribeInfo in
            if let tribeInfo = tribeInfo {
                messageRow.transactionMessage.tribeInfo = tribeInfo
                doneCompletion(self.messageId)
            }
        })
    }
    
    func configureView(messageRow: TransactionMessageRow, tribeInfo: GroupsManager.TribeInfo?, delegate: LinkPreviewDelegate) {
        guard let tribeInfo = tribeInfo else {
            return
        }
        self.delegate = delegate
        
        configureColors(messageRow: messageRow)
        addBubble(messageRow: messageRow)
        
        tribeButtonContainer?.isHidden = messageRow.isJoinedTribeLink(uuid: tribeInfo.uuid)
        tribeNameLabel.stringValue = tribeInfo.name ?? "title.not.available".localized
        tribeDescriptionLabel.stringValue = tribeInfo.description ?? "description.not.available".localized

        loadImage(messageRow: messageRow, tribeInfo: tribeInfo)
    }
    
    func configureColors(messageRow: TransactionMessageRow) {
        let incoming = messageRow.isIncoming()
        let color = incoming ? NSColor.Sphinx.SecondaryText : NSColor.Sphinx.SecondaryTextSent
        tribeDescriptionLabel.textColor = color
        
        tribeImageView.layer?.borderColor = color.cgColor
        
        let buttonColor = incoming ? NSColor.Sphinx.LinkReceivedButtonColor : NSColor.Sphinx.LinkSentButtonColor
        tribeButtonContainer.fillColor = buttonColor
    }
    
    func loadImage(messageRow: TransactionMessageRow, tribeInfo: GroupsManager.TribeInfo?) {
        let color = messageRow.isIncoming() ? NSColor.Sphinx.SecondaryText : NSColor.Sphinx.SecondaryTextSent
        let placeHolder = NSImage(named: "tribePlaceHolder")?.image(withTintColor: color)

        tribeImageView.borderColor = color.cgColor
        tribeImageView.bordered = true
        tribeImageView.gravity = .resizeAspectFill
        
        if let imageUrl = tribeInfo?.img?.trim(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
            MediaLoader.asyncLoadImage(imageView: tribeImageView, nsUrl: nsUrl, placeHolderImage: placeHolder, completion: {
                self.tribeImageView.bordered = false
                self.tribeImageView.gravity = .resizeAspectFill
                self.tribeImageView.customizeLayer()
            })
        } else {
            tribeImageView.image = placeHolder
        }
    }
    
    func loadTribeDetails(link: String, completion: @escaping (GroupsManager.TribeInfo?) -> ()) {
        if var tribeInfo = GroupsManager.sharedInstance.getGroupInfo(query: link) {
            API.sharedInstance.getTribeInfo(host: tribeInfo.host, uuid: tribeInfo.uuid, callback: { groupInfo in
                GroupsManager.sharedInstance.update(tribeInfo: &tribeInfo, from: groupInfo)
                completion(tribeInfo)
            }, errorCallback: {
                completion(nil)
            })
            return
        }
        completion(nil)
    }
    
    func addBubble(messageRow: TransactionMessageRow) {
        let width = getViewWidth(messageRow: messageRow)
        let height = CommonChatCollectionViewItem.getLinkPreviewHeight(messageRow: messageRow) - Constants.kBubbleBottomMargin
        let bubbleSize = CGSize(width: width, height: height)
        
        let consecutiveBubble = MessageBubbleView.ConsecutiveBubbles(previousBubble: true, nextBubble: false)
        let existingObject = messageRow.isJoinedTribeLink()

        if messageRow.isIncoming() {
            self.showIncomingLinkBubble(messageRow: messageRow, size: bubbleSize, consecutiveBubble: consecutiveBubble, bubbleMargin: 0, existingObject: existingObject)
        } else {
            self.showOutgoingLinkBubble(messageRow: messageRow, size: bubbleSize, consecutiveBubble: consecutiveBubble, bubbleMargin: 0, existingObject: existingObject)
        }
    }
    
    override func addConstraintsTo(bubbleView: NSView, messageRow: TransactionMessageRow) {
        super.addConstraintsTo(bubbleView: bubbleView, messageRow: messageRow)
        addConstraints()
    }
    
    @IBAction func seeTribeButtonClicked(_ sender: Any) {
        delegate?.didTapOnTribeButton()
    }
}
