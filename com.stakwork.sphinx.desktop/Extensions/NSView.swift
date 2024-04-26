//
//  NSView.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 13/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

let kViewBackgroundColorBoxTag = 1000

enum VerticalLocation: String {
    case bottom
    case top
    case bottomLeft
    case center
}

enum CornerRadius: String {
    case leftTop
    case leftBottom
    case rightTop
    case rightBottom
}

extension NSView {    
    private static let kRotationAnimationKey = "rotationanimationkey"
    
    public static let kBubbleLayerName: String = "bubble-layer"
    public static let kInvoiceDashedLayerName: String = "dashed-line"

    
    func rotate(duration: Double = 1) {
        self.layoutSubtreeIfNeeded()
        self.setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5))
        
        if layer?.animation(forKey: NSView.kRotationAnimationKey) == nil {
            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotationAnimation.fromValue = 0.0
            rotationAnimation.toValue = -1 * Float.pi * 2.0
            rotationAnimation.duration = duration
            rotationAnimation.repeatCount = Float.infinity
            layer?.add(rotationAnimation, forKey: NSView.kRotationAnimationKey)
        }
    }
    
    func stopRotating() {
        if layer?.animation(forKey: NSView.kRotationAnimationKey) != nil {
            layer?.removeAnimation(forKey: NSView.kRotationAnimationKey)
        }
    }
    
    func constraintTo(view: NSView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0.0).isActive = true
    }
    
    func getVerticalDottedLine(
        color: NSColor = NSColor.Sphinx.Body,
        frame: CGRect
    ) -> CAShapeLayer {
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
    
    func setAnchorPoint(anchorPoint:CGPoint) {
        self.wantsLayer = true
        
        if let layer = self.layer {
            var newPoint = NSPoint(x: self.bounds.size.width * anchorPoint.x, y: self.bounds.size.height * anchorPoint.y)
            var oldPoint = NSPoint(x: self.bounds.size.width * layer.anchorPoint.x, y: self.bounds.size.height * layer.anchorPoint.y)

            newPoint = newPoint.applying(layer.affineTransform())
            oldPoint = oldPoint.applying(layer.affineTransform())

            var position = layer.position

            position.x -= oldPoint.x
            position.x += newPoint.x

            position.y -= oldPoint.y
            position.y += newPoint.y

            layer.position = position
            layer.anchorPoint = anchorPoint
        }
    }
    
    func setBackgroundColor(color: NSColor) {
        let backgroundColorBox = NSBox(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        backgroundColorBox.title = ""
        backgroundColorBox.borderWidth = 0
        backgroundColorBox.borderColor = .clear
        backgroundColorBox.boxType = .custom
        backgroundColorBox.fillColor = color
        self.addSubview(backgroundColorBox)
    }
    
    func addShadow(
        location: VerticalLocation,
        color: NSColor = .black,
        opacity: Float = 0.5,
        radius: CGFloat = 5.0,
        bottomhHeight: CGFloat = 3,
        cornerRadius: CGFloat = 0
    ) {
        switch location {
        case .bottom:
            addShadow(offset: CGSize(width: 0, height: 3), color: color, opacity: opacity, radius: radius, cornerRadius: cornerRadius)
        case .bottomLeft:
            addShadow(offset: CGSize(width: -1, height: 2), color: color, opacity: opacity, radius: radius, cornerRadius: cornerRadius)
        case .top:
            addShadow(offset: CGSize(width: 0, height: -bottomhHeight), color: color, opacity: opacity, radius: radius, cornerRadius: cornerRadius)
        case .center:
            addShadow(offset: CGSize(width: 0, height: 0), color: color, opacity: opacity, radius: radius, cornerRadius: cornerRadius)
        }
    }
    
    func removeShadow() {
        self.layer?.shadowColor = NSColor.clear.cgColor
        self.layer?.shadowOpacity = 0.0
        self.layer?.shadowRadius = 0.0
    }
    
    func addShadow(offset: CGSize, color: NSColor = .black, opacity: Float = 0.5, radius: CGFloat = 5.0, cornerRadius: CGFloat = 0) {
        self.superview?.wantsLayer = true
        self.wantsLayer = true
        
        self.shadow = NSShadow()
        self.layer?.shadowOpacity = opacity
        self.layer?.shadowColor = color.cgColor
        self.layer?.shadowOffset = offset
        self.layer?.shadowRadius = radius
        self.layer?.masksToBounds = false
        
        if cornerRadius > 0 {
            let shapeRect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            self.layer?.shadowPath = NSBezierPath(roundedRect: shapeRect, xRadius: cornerRadius, yRadius: cornerRadius).cgPath
        }
    }
    
    func addDashedBorder(
        color: NSColor,
        fillColor: NSColor? = nil,
        size: CGSize,
        rect: CGRect? = nil,
        lineWidth: CGFloat = 3,
        dashPattern: [NSNumber] = [8,4],
        radius: CGFloat = 10
    ) {
        removeDashBorder()
        
        let color = color.cgColor
        
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        let frameSize = size
        let shapeRect = rect ?? CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: shapeRect.origin.x + shapeRect.width/2, y: shapeRect.origin.y + shapeRect.height/2)
        shapeLayer.fillColor = fillColor?.cgColor ?? NSColor.clear.cgColor
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineJoin = .round
        shapeLayer.lineDashPattern = dashPattern
        shapeLayer.name = NSView.kInvoiceDashedLayerName
        shapeLayer.path = NSBezierPath(roundedRect: shapeRect, xRadius: radius, yRadius: radius).cgPath
        
        self.wantsLayer = true
        self.layer?.addSublayer(shapeLayer)
    }
    
    func removeDashBorder() {
        self.layer?.sublayers?.forEach {
            if $0.name == NSView.kInvoiceDashedLayerName {
                $0.removeFromSuperlayer()
            }
        }
    }
    
    func bringSubviewToFront(_ view: NSView) {
        var theView = view
        self.sortSubviews({(viewA,viewB,rawPointer) in
            let view = rawPointer?.load(as: NSView.self)

            switch view {
            case viewA:
                return ComparisonResult.orderedDescending
            case viewB:
                return ComparisonResult.orderedAscending
            default:
                return ComparisonResult.orderedSame
            }
        }, context: &theView)
    }
    
    func removeAllSubviews() {
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
    }
    
    func addDownTriangle(color: NSColor? = nil){
        let width = self.frame.size.width
        let height = self.frame.size.height
        let path = CGMutablePath()

        path.move(to: CGPoint(x:width/2, y: 0))
        path.addLine(to: CGPoint(x:width, y:height))
        path.addLine(to: CGPoint(x:0, y:height))
        path.addLine(to: CGPoint(x:width/2, y:0))

        let shape = CAShapeLayer()
        shape.path = path
        shape.fillColor = (color ?? NSColor.white).cgColor
        shape.lineCap = .round
        shape.lineJoin = .round

        self.wantsLayer = true
        self.layer?.insertSublayer(shape, at: 0)
    }
    
    func drawReceivedBubbleArrow(
        color: NSColor,
        arrowWidth: CGFloat = 4
    ) {
        let arrowBezierPath = NSBezierPath()
        
        arrowBezierPath.move(to: CGPoint(x: 0, y: self.frame.height))
        arrowBezierPath.line(to: CGPoint(x: self.frame.width, y: self.frame.height))
        arrowBezierPath.line(to: CGPoint(x: self.frame.width, y: 0))
        arrowBezierPath.line(to: CGPoint(x: arrowWidth, y: 0))
        arrowBezierPath.line(to: CGPoint(x: 0, y: self.frame.height))
        arrowBezierPath.close()
        
        let messageArrowLayer = CAShapeLayer()
        messageArrowLayer.path = arrowBezierPath.cgPath
        
        messageArrowLayer.frame = self.bounds
        messageArrowLayer.fillColor = color.cgColor
        messageArrowLayer.name = "arrow"
        
        self.wantsLayer = true
        self.layer?.addSublayer(messageArrowLayer)
    }
    
    func setArrowColorTo(
        color: NSColor
    ) {
        ((self.layer?.sublayers?.filter { $0.name == "arrow" })?.first as? CAShapeLayer)?.fillColor = color.cgColor
    }
    
    func drawSentBubbleArrow(
        color: NSColor,
        arrowWidth: CGFloat = 7
    ) {
        let arrowBezierPath = NSBezierPath()
        
        arrowBezierPath.move(to: CGPoint(x: 0, y: self.frame.height))
        arrowBezierPath.line(to: CGPoint(x: self.frame.width, y: self.frame.height))
        arrowBezierPath.line(to: CGPoint(x: self.frame.width - arrowWidth, y: 0))
        arrowBezierPath.line(to: CGPoint(x: 0, y: 0))
        arrowBezierPath.line(to: CGPoint(x: 0, y: self.frame.height))
        arrowBezierPath.close()
        
        let messageArrowLayer = CAShapeLayer()
        messageArrowLayer.path = arrowBezierPath.cgPath
        
        messageArrowLayer.frame = self.bounds
        messageArrowLayer.fillColor = color.cgColor
        messageArrowLayer.name = "arrow"
        
        self.wantsLayer = true
        self.layer?.addSublayer(messageArrowLayer)
    }
}


