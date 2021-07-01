//
//  CommonBubbleView.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 18/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonBubbleView: NSView {
    
    public static let kBubbleLayerName: String = "bubble-layer"
    public static let kInvoiceDashedLayerName: String = "dashed-line" 
    
    override var isFlipped:Bool {
        get {
            return true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        self.wantsLayer = true
    }
    
    public struct ConsecutiveBubbles {
        var previousBubble: Bool
        var nextBubble: Bool
        
        init(previousBubble: Bool, nextBubble: Bool) {
            self.previousBubble = previousBubble
            self.nextBubble = nextBubble
        }
    }
    
    func getBubbleColors(messageRow: TransactionMessageRow, incoming: Bool) -> (CGColor, CGColor) {
        let canBeDecrypted = messageRow.canBeDecrypted()
        
        if incoming {
            if canBeDecrypted {
                return (NSColor.Sphinx.OldReceivedMsgBG.cgColor, NSColor.Sphinx.ReceivedBubbleBorder.cgColor)
            } else {
                return (NSColor.Sphinx.OldReceivedMsgBG.cgColor, NSColor.Sphinx.SecondaryRed.cgColor)
            }
        } else {
            return (NSColor.Sphinx.OldSentMsgBG.cgColor, NSColor.Sphinx.SentBubbleBorder.cgColor)
        }
    }
    
    func clearSubview(view: NSView) {
        clearBubbleLayer(view: view)
        
        self.subviews.forEach {
            if $0.tag == MessageBubbleView.kMessageLabelTag {
                $0.removeFromSuperview()
            }
        }
    }
    
    func clearBubbleLayer(view: NSView) {
        view.layer?.sublayers?.forEach {
            if [CommonBubbleView.kBubbleLayerName, CommonBubbleView.kInvoiceDashedLayerName, PictureBubbleView.kImageLayer].contains($0.name) {
                $0.removeFromSuperlayer()
            }
        }
    }
    
    func showIncomingEmptyBubble(messageRow: TransactionMessageRow, size: CGSize, consecutiveBubbles: ConsecutiveBubbles? = nil, bubbleMargin: CGFloat? = nil) {
        let view = self
        clearBubbleLayer(view: view)

        let consecutiveBubbles = consecutiveBubbles ?? ConsecutiveBubbles(previousBubble: false, nextBubble: false)

        let bezierPath = getIncomingBezierPath(size: size, bubbleMargin: bubbleMargin ?? Constants.kBubbleReceivedArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.getConsecutiveMessages())

        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.fillColor = NSColor.Sphinx.OldReceivedMsgBG.cgColor
        layer.strokeColor = NSColor.Sphinx.ReceivedBubbleBorder.cgColor
        layer.lineWidth = 1
        layer.name = CommonBubbleView.kBubbleLayerName

        view.wantsLayer = true
        view.layer?.masksToBounds = false
        view.layer?.addSublayer(layer)
        self.addMessageShadow(layer: layer)
    }
    
    func showOutgoingEmptyBubble(messageRow: TransactionMessageRow, size: CGSize, consecutiveBubbles: ConsecutiveBubbles? = nil, bubbleMargin: CGFloat? = nil) {
        let view = self
        clearBubbleLayer(view: view)

        let consecutiveBubbles = consecutiveBubbles ?? ConsecutiveBubbles(previousBubble: false, nextBubble: false)

        let bezierPath = getOutgoingBezierPath(size: size, bubbleMargin: bubbleMargin ?? Constants.kBubbleSentArrowMargin, consecutiveBubbles: consecutiveBubbles, consecutiveMessages: messageRow.getConsecutiveMessages())

        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        layer.fillColor = NSColor.Sphinx.OldSentMsgBG.cgColor
        layer.strokeColor = NSColor.Sphinx.SentBubbleBorder.cgColor
        layer.lineWidth = 1
        layer.name = CommonBubbleView.kBubbleLayerName

        view.wantsLayer = true
        view.layer?.masksToBounds = false
        view.layer?.addSublayer(layer)
        self.addMessageShadow(layer: layer)
    }
    
    func getIncomingBezierPath(size: CGSize,
                               bubbleMargin: CGFloat,
                               consecutiveBubbles: ConsecutiveBubbles,
                               consecutiveMessages: TransactionMessage.ConsecutiveMessages) -> NSBezierPath {
        
        let curveSize = Constants.kBubbleCurveSize
        let width = size.width
        let height = size.height
        let halfCurveSize = curveSize/2
        let bezierPath = NSBezierPath()
        bezierPath.move(to: CGPoint(x: width - curveSize, y: height))
        bezierPath.line(to: CGPoint(x: curveSize + bubbleMargin, y: height))
        
        if consecutiveBubbles.nextBubble || consecutiveMessages.nextMessage {
            bezierPath.line(to: CGPoint(x: bubbleMargin, y: height))
            bezierPath.line(to: CGPoint(x: bubbleMargin, y: height - curveSize))
        } else {
            bezierPath.curve(to: CGPoint(x: bubbleMargin, y: height - curveSize),
                             controlPoint1: CGPoint(x: bubbleMargin + halfCurveSize, y: height),
                             controlPoint2: CGPoint(x: bubbleMargin, y: height - halfCurveSize))
        }
        
        bezierPath.line(to: CGPoint(x: bubbleMargin, y: curveSize))
        
        if consecutiveBubbles.previousBubble {
            bezierPath.line(to: CGPoint(x: bubbleMargin, y: 0))
            bezierPath.line(to: CGPoint(x: width, y: 0))
        } else {
            if consecutiveMessages.previousMessage {
                bezierPath.line(to: CGPoint(x: bubbleMargin, y: 0))
            } else {
                bezierPath.line(to: CGPoint(x: 0, y: 0))
            }
            bezierPath.line(to: CGPoint(x: width - curveSize, y: 0))
            bezierPath.curve(to: CGPoint(x: width, y: curveSize),
                             controlPoint1: CGPoint(x: width - halfCurveSize, y: 0),
                             controlPoint2: CGPoint(x: width, y: halfCurveSize))
        }
        
        if consecutiveBubbles.nextBubble {
            bezierPath.line(to: CGPoint(x: width, y: height))
        } else {
            bezierPath.line(to: CGPoint(x: width, y: height - curveSize))
            bezierPath.curve(to: CGPoint(x: width - curveSize, y: height),
                             controlPoint1: CGPoint(x: width, y: height - halfCurveSize),
                             controlPoint2: CGPoint(x: width - halfCurveSize, y: height))
        }
        
        bezierPath.close()
        return bezierPath
    }
    
    func getOutgoingBezierPath(size: CGSize,
                               bubbleMargin: CGFloat,
                               consecutiveBubbles: ConsecutiveBubbles,
                               consecutiveMessages: TransactionMessage.ConsecutiveMessages) -> NSBezierPath {
        
        let curveSize = Constants.kBubbleCurveSize
        let width = size.width
        let height = size.height
        let halfCurveSize = curveSize/2
        let bezierPath = NSBezierPath()
        
        bezierPath.move(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height))
        
        if consecutiveBubbles.nextBubble {
            bezierPath.line(to: CGPoint(x: 0, y: height))
        } else {
            bezierPath.line(to: CGPoint(x: curveSize, y: height))
            bezierPath.curve(to: CGPoint(x: 0, y: height - curveSize),
                             controlPoint1: CGPoint(x: halfCurveSize, y: height),
                             controlPoint2: CGPoint(x: 0, y: height - halfCurveSize))
        }
        
        if consecutiveBubbles.previousBubble {
            bezierPath.line(to: CGPoint(x: 0, y: 0))
            bezierPath.line(to: CGPoint(x: width - bubbleMargin, y: 0))
        } else {
            bezierPath.line(to: CGPoint(x: 0, y: curveSize))
            bezierPath.curve(to: CGPoint(x: curveSize, y: 0),
                             controlPoint1: CGPoint(x: 0, y: halfCurveSize),
                             controlPoint2: CGPoint(x: halfCurveSize, y: 0))
            if consecutiveMessages.previousMessage {
                bezierPath.line(to: CGPoint(x: width - bubbleMargin, y: 0))
            } else {
                bezierPath.line(to: CGPoint(x: width, y: 0))
            }
        }
        
        bezierPath.line(to: CGPoint(x: width - bubbleMargin, y: curveSize))
        bezierPath.line(to: CGPoint(x: width - bubbleMargin, y: height - curveSize))
        
        if consecutiveBubbles.nextBubble || consecutiveMessages.nextMessage {
            bezierPath.line(to: CGPoint(x: width - bubbleMargin, y: height))
            bezierPath.line(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height))
        } else {
            bezierPath.curve(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height),
                             controlPoint1: CGPoint(x: width - bubbleMargin, y: height - halfCurveSize),
                             controlPoint2: CGPoint(x: width - (halfCurveSize + bubbleMargin), y: height))
        }
        bezierPath.close()
        return bezierPath
    }
    
    func getIncomingInvoiceTopBezierPath(width: CGFloat, height: CGFloat, curveSize: CGFloat, bubbleMargin: CGFloat) -> NSBezierPath {
        let halfCurveSize = curveSize/2
        let bezierPath = NSBezierPath()
        bezierPath.move(to: CGPoint(x: width - curveSize, y: height))
        bezierPath.line(to: CGPoint(x: curveSize + bubbleMargin, y: height))
        bezierPath.curve(to: CGPoint(x: bubbleMargin, y: height - curveSize),
                         controlPoint1: CGPoint(x: bubbleMargin + halfCurveSize, y: height),
                         controlPoint2: CGPoint(x: bubbleMargin, y: height - halfCurveSize))
        bezierPath.line(to: CGPoint(x: bubbleMargin, y: curveSize))
        bezierPath.line(to: CGPoint(x: 0, y: 0))
        bezierPath.line(to: CGPoint(x: width - curveSize, y: 0))
        bezierPath.curve(to: CGPoint(x: width, y: curveSize),
                         controlPoint1: CGPoint(x: width - halfCurveSize, y: 0),
                         controlPoint2: CGPoint(x: width, y: halfCurveSize))
        bezierPath.line(to: CGPoint(x: width, y: height - curveSize))
        bezierPath.curve(to: CGPoint(x: width - curveSize, y: height),
                         controlPoint1: CGPoint(x: width, y: height - halfCurveSize),
                         controlPoint2: CGPoint(x: width - halfCurveSize, y: height))
        bezierPath.close()
        return bezierPath
    }
    
    func getIncomingInvoiceBottomBezierPath(width: CGFloat, height: CGFloat, curveSize: CGFloat, bubbleMargin: CGFloat, rightBubbleMargin: CGFloat,  paid: Bool) -> NSBezierPath {
        let halfCurveSize = curveSize/2
        let bezierPath = NSBezierPath()
        bezierPath.move(to: CGPoint(x: width - curveSize, y: height))
        bezierPath.line(to: CGPoint(x: curveSize + bubbleMargin, y: height))
        bezierPath.curve(to: CGPoint(x: bubbleMargin, y: height - curveSize),
                         controlPoint1: CGPoint(x: bubbleMargin + halfCurveSize, y: height),
                         controlPoint2: CGPoint(x: bubbleMargin, y: height - halfCurveSize))
        bezierPath.line(to: CGPoint(x: bubbleMargin, y: curveSize))
        bezierPath.curve(to: CGPoint(x: bubbleMargin + curveSize, y: 0),
                         controlPoint1: CGPoint(x: bubbleMargin, y: halfCurveSize),
                         controlPoint2: CGPoint(x: bubbleMargin + halfCurveSize, y: 0))
        bezierPath.line(to: CGPoint(x: width - curveSize, y: 0))
        
        if paid {
            bezierPath.line(to: CGPoint(x: width + rightBubbleMargin, y: 0))
            bezierPath.line(to: CGPoint(x: width, y: curveSize))
        } else {
            bezierPath.curve(to: CGPoint(x: width, y: curveSize),
                             controlPoint1: CGPoint(x: width - halfCurveSize, y: 0),
                             controlPoint2: CGPoint(x: width, y: halfCurveSize))
        }
        bezierPath.line(to: CGPoint(x: width, y: height - curveSize))
        bezierPath.curve(to: CGPoint(x: width - curveSize, y: height),
                         controlPoint1: CGPoint(x: width, y: height - halfCurveSize),
                         controlPoint2: CGPoint(x: width - halfCurveSize, y: height))
        bezierPath.close()
        return bezierPath
    }
    
    func getOutgoingInvoiceTopBezierPath(width: CGFloat, height: CGFloat, curveSize: CGFloat, bubbleMargin: CGFloat, leftBubbleMargin: CGFloat) -> NSBezierPath {
        let halfCurveSize = curveSize/2
        let bezierPath = NSBezierPath()
        bezierPath.move(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height))
        bezierPath.line(to: CGPoint(x: leftBubbleMargin + curveSize, y: height))
        bezierPath.curve(to: CGPoint(x: leftBubbleMargin, y: height - curveSize),
                         controlPoint1: CGPoint(x: leftBubbleMargin + halfCurveSize, y: height),
                         controlPoint2: CGPoint(x: leftBubbleMargin, y: height - halfCurveSize))
        bezierPath.line(to: CGPoint(x: leftBubbleMargin, y: curveSize))
        bezierPath.curve(to: CGPoint(x: leftBubbleMargin + curveSize, y: 0),
                         controlPoint1: CGPoint(x: leftBubbleMargin, y: halfCurveSize),
                         controlPoint2: CGPoint(x: leftBubbleMargin + halfCurveSize, y: 0))
        bezierPath.line(to: CGPoint(x: width, y: 0))
        bezierPath.line(to: CGPoint(x: width - bubbleMargin, y: curveSize))
        bezierPath.line(to: CGPoint(x: width - bubbleMargin, y: height - curveSize))
        bezierPath.curve(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height),
                         controlPoint1: CGPoint(x: width - bubbleMargin, y: height - halfCurveSize),
                         controlPoint2: CGPoint(x: width - (halfCurveSize + bubbleMargin), y: height))
        return bezierPath
    }
    
    func getOutgoingInvoiceBottomBezierPath(width: CGFloat, height: CGFloat, curveSize: CGFloat, bubbleMargin: CGFloat, leftBubbleMargin: CGFloat, paid: Bool) -> NSBezierPath {
        let halfCurveSize = curveSize/2
        let bezierPath = NSBezierPath()
        bezierPath.move(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height))
        bezierPath.line(to: CGPoint(x: leftBubbleMargin + curveSize, y: height))
        bezierPath.curve(to: CGPoint(x: leftBubbleMargin, y: height - curveSize),
                         controlPoint1: CGPoint(x: leftBubbleMargin + halfCurveSize, y: height),
                         controlPoint2: CGPoint(x: leftBubbleMargin, y: height - halfCurveSize))
        bezierPath.line(to: CGPoint(x: leftBubbleMargin, y: curveSize))
        if paid {
            bezierPath.line(to: CGPoint(x: 0, y: 0))
        } else {
            bezierPath.curve(to: CGPoint(x: leftBubbleMargin + curveSize, y: 0),
                             controlPoint1: CGPoint(x: leftBubbleMargin, y: halfCurveSize),
                             controlPoint2: CGPoint(x: leftBubbleMargin + halfCurveSize, y: 0))
        }
        bezierPath.line(to: CGPoint(x: width - (curveSize + bubbleMargin), y: 0))
        bezierPath.curve(to: CGPoint(x: width - bubbleMargin, y: curveSize),
                         controlPoint1: CGPoint(x: width - (halfCurveSize + bubbleMargin), y: 0),
                         controlPoint2: CGPoint(x: width - bubbleMargin, y: halfCurveSize))
        bezierPath.line(to: CGPoint(x: width - bubbleMargin, y: height - curveSize))
        bezierPath.curve(to: CGPoint(x: width - (curveSize + bubbleMargin), y: height),
                         controlPoint1: CGPoint(x: width - bubbleMargin, y: height - halfCurveSize),
                         controlPoint2: CGPoint(x: width - (halfCurveSize + bubbleMargin), y: height))
        return bezierPath
    }
    
    func getDashedLine(color: NSColor = NSColor.Sphinx.Body, frame: CGRect) -> CAShapeLayer {
        let cgColor = color.cgColor
        
        let shapeLayer: CAShapeLayer = CAShapeLayer()
        let frameSize = frame.size
        let shapeRect = frame
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frame.origin.x + frameSize.width / 2, y: frame.origin.y)
        shapeLayer.fillColor = cgColor
        shapeLayer.strokeColor = cgColor
        shapeLayer.lineWidth = 1
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        shapeLayer.lineDashPattern = [5, 5]
        
        let path: CGMutablePath = CGMutablePath()
        path.move(to: CGPoint(x: frame.origin.x, y: frame.origin.y))
        path.addLine(to: CGPoint(x: frame.origin.x + frame.width, y: frame.origin.y))
        shapeLayer.path = path
        
        return shapeLayer
    }
    
    func addShadowTo(layer: CALayer, color: NSColor = NSColor.Sphinx.Shadow) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1.5)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 1.5
        layer.shouldRasterize = true
    }
    
    func addMessageShadow(layer: CALayer, color: NSColor = NSColor.Sphinx.Shadow) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: 1.5, height: 1.0)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 2
        layer.shouldRasterize = true
        layer.rasterizationScale = 5
    }
}
