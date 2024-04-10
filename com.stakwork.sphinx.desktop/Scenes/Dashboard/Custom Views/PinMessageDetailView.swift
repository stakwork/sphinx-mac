//
//  PinMessageDetailView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 24/05/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class PinMessageDetailView: NSView, LoadableNib {
    
    weak var delegate: PinnedMessageViewDelegate?
    
    @IBOutlet var contentView: NSView!

    @IBOutlet weak var backgroundBox: NSBox!
    @IBOutlet weak var avatarView: ChatSmallAvatarView!
    @IBOutlet weak var usernameLabel: NSTextField!
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var arrowView: NSView!
    @IBOutlet weak var unpinButtonContainer: NSView!
    @IBOutlet weak var unpinButton: CustomButton!
    @IBOutlet weak var containerButton: CustomButton!
    
    var messageId: Int? = nil
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        drawArrow()
        addClickEvent()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        
        unpinButton.cursor = .pointingHand
        containerButton.cursor = .pointingHand
        
        drawArrow()
        addClickEvent()
    }
    
    func addClickEvent() {
        let click = NSClickGestureRecognizer(target: self, action: #selector(shouldDismissView))
        backgroundBox.addGestureRecognizer(click)
    }
    
    @objc func shouldDismissView() {
        self.messageId = nil
        self.isHidden = true
    }
    
    func drawArrow() {
        let arrowBezierPath = NSBezierPath()
        
        arrowBezierPath.move(to: CGPoint(x: arrowView.frame.width, y: 0))
        arrowBezierPath.line(to: CGPoint(x: arrowView.frame.width, y: arrowView.frame.height))
        arrowBezierPath.line(to: CGPoint(x: 0, y: arrowView.frame.height))
        arrowBezierPath.line(to: CGPoint(x: 4, y: 0))
        arrowBezierPath.line(to: CGPoint(x: 0, y: 0))
        arrowBezierPath.close()
        
        let messageArrowLayer = CAShapeLayer()
        messageArrowLayer.path = arrowBezierPath.cgPath
        
        messageArrowLayer.frame = CGRect(
            x: 0, y: 0, width: arrowView.frame.width, height: arrowView.frame.height
        )

        messageArrowLayer.fillColor = NSColor.Sphinx.SentMsgBG.cgColor
        
        arrowView.wantsLayer = true
        arrowView.layer?.masksToBounds = false
        arrowView.layer?.addSublayer(messageArrowLayer)
    }
    
    func configureWith(
        messageId: Int,
        delegate: PinnedMessageViewDelegate
    ) {
        if let message = TransactionMessage.getMessageWith(id: messageId) {
            self.delegate = delegate
            self.messageId = messageId
            
            if message.isOutgoing() {
                if let owner = UserContact.getOwner() {
                    avatarView.configureForUserWith(
                        color: owner.getColor(),
                        alias: owner.nickname,
                        picture: owner.avatarUrl
                    )
                    
                    usernameLabel.stringValue = owner.nickname ?? "Unknown"
                    usernameLabel.textColor = owner.getColor()
                }
            } else {
                avatarView.configureForSenderWith(message: message)
                
                usernameLabel.stringValue = message.senderAlias ?? "Unknown"
                usernameLabel.textColor = ChatHelper.getSenderColorFor(message: message)
            }
            
            messageLabel.stringValue = message.bubbleMessageContentString ?? ""
            unpinButtonContainer.isHidden = message.chat?.isMyPublicGroup() == false
            
            self.isHidden = false
        }
    }
    
    @IBAction func containerButtonClicked(_ sender: Any) {
        if let messageId = self.messageId {
            delegate?.shouldNavigateTo(messageId: messageId)
        }
        shouldDismissView()
    }
    
    @IBAction func unpinMessageButtoniClicked(_ sender: Any) {
        if let messageId = messageId {
            delegate?.didTapUnpinButtonFor(messageId: messageId)
            shouldDismissView()
        }
    }
}
