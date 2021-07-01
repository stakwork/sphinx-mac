//
//  PictureBubbleView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol PictureBubbleDelegate {
    func didTapAttachmentRow()
}

class PictureBubbleView: CommonBubbleView {
    
    var delegate: PictureBubbleDelegate?
    
    public static let kImageLayer = "image-layer"
    
    override func mouseDown(with event: NSEvent) {
        delegate?.didTapAttachmentRow()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func clearBubbleView() {
        clearSubview(view: self)
    }
    
    func getBubbleColors(messageRow: TransactionMessageRow) -> (CGColor, CGColor) {
        if messageRow.isIncoming() {
            return (NSColor.Sphinx.OldReceivedMsgBG.cgColor, NSColor.Sphinx.ReceivedBubbleBorder.cgColor)
        } else {
            return (NSColor.Sphinx.OldSentMsgBG.cgColor, NSColor.Sphinx.SentBubbleBorder.cgColor)
        }
    }
    
    func showIncomingPictureBubble(messageRow: TransactionMessageRow,
                                   size: CGSize,
                                   image: NSImage? = nil,
                                   gifData: Data? = nil,
                                   contentMode: CALayerContentsGravity = .resizeAspectFill) {
        
        clearSubview(view: self)

        let consecutiveBubbles = getConsecutiveBubble(messageRow: messageRow)
        let bubbleColors = getBubbleColors(messageRow: messageRow)

        let bezierPath = getIncomingBezierPath(size: size, bubbleMargin: Constants.kBubbleReceivedArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.fillColor = bubbleColors.0
        layer.strokeColor = bubbleColors.1
        layer.name = CommonBubbleView.kBubbleLayerName

        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.layer?.addSublayer(layer)
        addMessageShadow(layer: layer)
        
        let imageOrGifAvailable = image != nil || gifData != nil
        
        if imageOrGifAvailable {
            addStaticImageInBubble(image: image, gifData: gifData, frame: rect, path: bezierPath, contentMode: contentMode, strokeColor: bubbleColors.1)
            
            if messageRow.transactionMessage.isVideo() {
                addVideoLayerBubble(frame: rect, path: bezierPath)
            }
        }
    }
    
    func showOutgoingPictureBubble(messageRow: TransactionMessageRow,
                                   size: CGSize,
                                   image: NSImage? = nil,
                                   gifData: Data? = nil,
                                   contentMode: CALayerContentsGravity = .resizeAspectFill) {
        
        clearSubview(view: self)

        let consecutiveBubbles = getConsecutiveBubble(messageRow: messageRow)
        let bubbleColors = getBubbleColors(messageRow: messageRow)
        
        let bezierPath = getOutgoingBezierPath(size: size, bubbleMargin: 6, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.transactionMessage.consecutiveMessages)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.fillColor = bubbleColors.0
        layer.strokeColor = bubbleColors.1
        layer.name = CommonBubbleView.kBubbleLayerName
        
        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.layer?.addSublayer(layer)
        addMessageShadow(layer: layer)
        
        let imageOrGifAvailable = image != nil || gifData != nil

        if imageOrGifAvailable {
            addStaticImageInBubble(image: image, gifData: gifData, frame: rect, path: bezierPath, contentMode: contentMode, strokeColor: bubbleColors.1)
            
            if messageRow.transactionMessage.isVideo() {
                addVideoLayerBubble(frame: rect, path: bezierPath)
            }
        }
    }
    
    func getConsecutiveBubble(messageRow: TransactionMessageRow) -> ConsecutiveBubbles {
        let isDirectPayment = messageRow.isDirectPayment
        let attachmentHasText = messageRow.transactionMessage.hasMessageContent() && !isDirectPayment
        let isPaidAttachment = messageRow.isPaidAttachment
        let isBoosted = messageRow.isBoosted
        let isReply = messageRow.isReply
        
        if messageRow.isIncoming() {
            return ConsecutiveBubbles(previousBubble: isDirectPayment || isReply, nextBubble: attachmentHasText || isPaidAttachment || isBoosted)
        } else {
            return ConsecutiveBubbles(previousBubble: isDirectPayment || isReply, nextBubble: attachmentHasText || isBoosted)
        }
    }
    
    func addAnimatedImageInBubble(data: Data) {
        if let animation = data.createGIFAnimation(), let layer = self.getImageLayer() {
            layer.contents = nil
            layer.add(animation, forKey: "contents")
        }
    }
    
    func clearData() {
        if let layer = self.getImageLayer() {
            layer.removeAllAnimations()
            layer.contents = nil
        }
    }
    
    func addStaticImageInBubble(image: NSImage? = nil, gifData: Data? = nil, frame: CGRect, path: NSBezierPath, contentMode: CALayerContentsGravity = .resizeAspectFill, strokeColor: CGColor) {
        addImageInBubble(image: image?.cgImage, gifData: gifData, frame: frame, path: path, contentMode: contentMode, strokeColor: strokeColor)
    }
    
    func addImageInBubble(image: CGImage? = nil, gifData: Data? = nil, frame: CGRect, path: NSBezierPath, contentMode: CALayerContentsGravity = .resizeAspectFill, strokeColor: CGColor) {
        let imageLayer = CAShapeLayer()
        imageLayer.contentsGravity = contentMode
        imageLayer.frame = frame
        imageLayer.strokeColor = strokeColor
        imageLayer.name = PictureBubbleView.kImageLayer
        
        if let gifData = gifData {
            DispatchQueue.global(qos: .background).async {
                if let animation = gifData.createGIFAnimation() {
                    DispatchQueue.main.async {
                        imageLayer.contents = nil
                        imageLayer.add(animation, forKey: "contents")
                    }
                }
            }
        } else if let image = image {
            imageLayer.contents = image
            imageLayer.removeAllAnimations()
        }

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        imageLayer.mask = maskLayer
        
        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.layer?.addSublayer(imageLayer)
        addMessageShadow(layer: imageLayer)
    }
    
    func getImageLayer() -> CAShapeLayer? {
        for layer in self.layer?.sublayers ?? []  {
            if layer.name == PictureBubbleView.kImageLayer {
                if let layer = layer as? CAShapeLayer {
                    return layer
                }
            }
        }
        return nil
    }
    
    func addVideoLayerBubble(frame: CGRect, path: NSBezierPath) {
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.frame = frame

        layer.fillColor = NSColor.black.withAlphaComponent(0.5).cgColor

        self.layer?.addSublayer(layer)
    }
}
