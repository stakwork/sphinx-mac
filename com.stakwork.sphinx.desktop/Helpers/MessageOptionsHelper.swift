//
//  MessageOptionsHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 16/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol MessageOptionsDelegate: AnyObject {
    func shouldDeleteMessage(message: TransactionMessage)
    func shouldReplyToMessage(message: TransactionMessage)
    func shouldBoostMessage(message: TransactionMessage)
    func shouldPerformChatAction(action: TransactionMessage.MessageActionsItem)
}

class MessageOptionsHelper {
    
    weak var delegate: MessageOptionsDelegate?
    
    class var sharedInstance : MessageOptionsHelper {
        struct Static {
            static let instance = MessageOptionsHelper()
        }
        return Static.instance
    }
    
    var menuView: NSView? = nil
    var message: TransactionMessage? = nil
    var chat: Chat? = nil
    
    var menuOptionsWidth:CGFloat = 140
    let optionsHeight:CGFloat = 40
    let iconWidth:CGFloat = 40
    let menuVerticalMargin: CGFloat = 5
    
    public enum VerticalPosition: Int {
        case Top
        case Bottom
    }
    
    public enum HorizontalPosition: Int {
        case Center
        case Left
        case Right
    }
    
    func showMenuFor(message: TransactionMessage? = nil, chat: Chat? = nil, in view: NSView, from button: NSButton, with delegate: MessageOptionsDelegate) {
        
        if let m = self.message, m.id == message?.id{
            hideMenu()
            return
        }
        
        if let ch = self.chat, ch.id == chat?.id {
            hideMenu()
            return
        }
        
        hideMenu()
        menuOptionsWidth = (chat != nil) ? 160 : 140
        
        self.delegate = delegate
        self.message = message
        self.chat = chat
        
        let frameInView = button.superview!.convert(button.frame, to: view)
        let windowHeight = NSApplication.shared.keyWindow?.frame.size.height ?? 735
        let vPosition: VerticalPosition = (frameInView.origin.y < windowHeight / 2) ? .Top : .Bottom
        let hPosition: HorizontalPosition = (frameInView.origin.x > (view.frame.width - (menuOptionsWidth / 2) - 12)) ? .Right : .Center
        
        let messageOptions = getActionsMenuOptions()
        let optionsCount = messageOptions.count
        let bubbleColor = getBubbleColor(message: message)
        
        let menuFrame = getMenuFrame(vPosition: vPosition, hPosition: hPosition, buttonFrame: frameInView, optionsCount: optionsCount)
        menuView = MenuOptionsView(frame: menuFrame)
        
        if let menuView = menuView {
            addBackLayer(on: menuView, frame: menuView.bounds, backColor: bubbleColor, vPosition: vPosition, hPosition: hPosition)
            addMenuOptions(options: messageOptions, on: menuView)
            
            view.addSubview(menuView)
        }
    }
    
    func getBubbleColor(message: TransactionMessage?) -> NSColor {
        if message?.isIncoming() ?? false {
            return NSColor.Sphinx.OldReceivedMsgBG
        } else {
            return NSColor.Sphinx.OldSentMsgBG
        }
    }
    
    func hideMenu() {
        self.message = nil
        self.chat = nil
        self.delegate = nil
        
        if let menuView = menuView {
            menuView.removeFromSuperview()
            self.menuView = nil
        }
    }
    
    func getMenuFrame(vPosition: VerticalPosition, hPosition: HorizontalPosition, buttonFrame: CGRect, optionsCount: Int) -> CGRect {
        let height = CGFloat(optionsCount) * optionsHeight + (menuVerticalMargin * 2)
        let arrowPosition = getArrowPosition(width: menuOptionsWidth, hPosition: hPosition)
        
        let x = buttonFrame.origin.x + (buttonFrame.width / 2) - arrowPosition
        var y: CGFloat = 0
        
        switch (vPosition) {
        case .Top:
            y = buttonFrame.origin.y + buttonFrame.height + 10
        case .Bottom:
            y = buttonFrame.origin.y - 10 - height
        }
        return NSRect(x: x, y: y, width: menuOptionsWidth, height: height)
    }
    
    func addMenuOptions(options: [(tag: TransactionMessage.MessageActionsItem, icon: String?, iconImage: String?, label: String)], on view: NSView) {
        var index = 0
        for (tag, icon, iconImage, label) in options {
            let y = menuVerticalMargin + CGFloat(index) * optionsHeight
            
            let shouldShowSeparator = index < options.count - 1
            let optionView = MessageOptionView(frame: CGRect(x: 0, y: y, width: view.frame.size.width, height: optionsHeight))

            let color = getColorFor(tag)
            let option = MessageOptionView.Option(icon: icon, iconImage: iconImage, title: label, tag: tag.rawValue, color: color, showLine: shouldShowSeparator)
            optionView.configure(option: option, delegate: self)
            
            view.addSubview(optionView)
            
            index = index + 1
        }
    }
    
    func getColorFor(_ tag: TransactionMessage.MessageActionsItem) -> NSColor {
        switch(tag) {
        case .Delete:
            return NSColor.Sphinx.BadgeRed
        default:
            return NSColor.Sphinx.Text
        }
    }
    
    func getActionsMenuOptions() -> [(tag: TransactionMessage.MessageActionsItem, icon: String?, iconImage: String?, label: String)] {
        if let message = message {
            return message.getActionsMenuOptions()
        }
        if let chat = chat {
            return chat.getActionsMenuOptions()
        }
        return []
    }
    
    func getGroupOptions() -> [(tag: TransactionMessage.MessageActionsItem, icon: String?, iconImage: String?, label: String)] {
        var options = [(tag: TransactionMessage.MessageActionsItem, icon: String?, iconImage: String?, label: String)]()
        options.append((TransactionMessage.MessageActionsItem.Copy, "", nil, "copy.text".localized))
        options.append((TransactionMessage.MessageActionsItem.CopyLink, "link", nil, "copy.link".localized))
        return options
    }
    
    func addBackLayer(on view: NSView, frame: CGRect, backColor: NSColor, vPosition: VerticalPosition, hPosition: HorizontalPosition) {
        let layerFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        let menuBubbleLayer = CAShapeLayer()
        menuBubbleLayer.path = getMenuBubblePath(rect: layerFrame, vPosition: vPosition, hPosition: hPosition).cgPath
        menuBubbleLayer.frame = layerFrame
        menuBubbleLayer.fillColor = backColor.cgColor
        
        addShadowTo(layer: menuBubbleLayer)
        
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        view.layer?.addSublayer(menuBubbleLayer)
    }
    
    func addShadowTo(layer: CALayer, color: NSColor = NSColor.Sphinx.Shadow) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 7
        layer.shouldRasterize = true
    }
    
    func getArrowPosition(width: CGFloat, hPosition: HorizontalPosition) -> CGFloat {
        var arrowPosition:CGFloat = 0
        switch (hPosition) {
        case .Center:
            arrowPosition = width / 2
        case .Left:
            arrowPosition = width / 10
        case .Right:
            arrowPosition = width - 12
        }
        return arrowPosition
    }
    
    func getMenuBubblePath(rect: CGRect, vPosition: VerticalPosition, hPosition: HorizontalPosition) -> NSBezierPath {
        let curveSize: CGFloat = 3
        let halfCurveSize = curveSize/2
        
        let width = rect.size.width
        let height: CGFloat = rect.size.height
        let adjustedY: CGFloat = 0
        
        let arrowPosition = getArrowPosition(width: width, hPosition: hPosition)
        let arrowWidth: CGFloat = 8
        let halfArrowWidth = arrowWidth / 2
        let arrowHeight: CGFloat = 5
        
        let bezierPath = NSBezierPath()
        
        bezierPath.move(to: CGPoint(x: width - curveSize, y: height))
        if vPosition == .Top {
            bezierPath.line(to: CGPoint(x: arrowPosition + halfArrowWidth, y: height))
            bezierPath.line(to: CGPoint(x: arrowPosition, y: height + arrowHeight))
            bezierPath.line(to: CGPoint(x: arrowPosition - halfArrowWidth, y: height))
            
        }
        bezierPath.line(to: CGPoint(x: curveSize, y: height))
        bezierPath.curve(to: CGPoint(x: 0, y: height - curveSize),
                         controlPoint1: CGPoint(x: halfCurveSize, y: height),
                         controlPoint2: CGPoint(x: 0, y: height - halfCurveSize))
        
        bezierPath.line(to: CGPoint(x: 0, y: curveSize + adjustedY))
        bezierPath.curve(to: CGPoint(x: curveSize, y: adjustedY),
                         controlPoint1: CGPoint(x: 0, y: adjustedY + halfCurveSize),
                         controlPoint2: CGPoint(x: halfCurveSize, y: adjustedY))
        if vPosition == .Bottom {
            bezierPath.line(to: CGPoint(x: arrowPosition - halfArrowWidth, y: adjustedY))
            bezierPath.line(to: CGPoint(x: arrowPosition, y: adjustedY - arrowHeight))
            bezierPath.line(to: CGPoint(x: arrowPosition + halfArrowWidth, y: adjustedY))
        }
        bezierPath.line(to: CGPoint(x: width - curveSize, y: adjustedY))
        bezierPath.curve(to: CGPoint(x: width, y: adjustedY + curveSize),
                         controlPoint1: CGPoint(x: width - halfCurveSize, y: adjustedY),
                         controlPoint2: CGPoint(x: width, y: adjustedY + halfCurveSize))

        bezierPath.line(to: CGPoint(x: width, y: height - curveSize))
        bezierPath.curve(to: CGPoint(x: width - curveSize, y: height),
                         controlPoint1: CGPoint(x: width, y: height - halfCurveSize),
                         controlPoint2: CGPoint(x: width - halfCurveSize, y: height))
        
        bezierPath.close()
        return bezierPath
    }
}

extension MessageOptionsHelper : MessageOptionViewDelegate {
    func didTapButton(tag: Int) {
        guard let option = TransactionMessage.MessageActionsItem(rawValue: tag) else {
            return
        }
        
        if let _ = chat {
            delegate?.shouldPerformChatAction(action: option)
            return
        }
        
        guard let message = message else {
            return
        }
        
        let bubbleContainer = menuView?.superview
        
        switch(option) {
        case .Copy:
            ClipboardHelper.copyToClipboard(text: message.getMessageContent(), message: "text.copied.clipboard".localized, bubbleContainer: bubbleContainer)
            break
        case .CopyLink:
            ClipboardHelper.copyToClipboard(text: message.messageContent?.stringFirstLink ?? "", message: "link.copied.clipboard".localized, bubbleContainer: bubbleContainer)
            break
        case .CopyPubKey:
            ClipboardHelper.copyToClipboard(text: message.messageContent?.stringFirstPubKey ?? "", message: "pub.key.copied.clipboard".localized, bubbleContainer: bubbleContainer)
            break
        case .CopyCallLink:
            ClipboardHelper.copyToClipboard(text: message.messageContent ?? "", message: "call.link.copied.clipboard".localized, bubbleContainer: bubbleContainer)
            break
        case .Delete:
            delegate?.shouldDeleteMessage(message: message)
            break
        case .Reply:
            delegate?.shouldReplyToMessage(message: message)
            break
        case .Save:
            shouldSaveFile(message: message, bubbleContainer: bubbleContainer)
            break
        case .Boost:
            delegate?.shouldBoostMessage(message: message)
            break
        default:
            break
        }
        hideMenu()
    }
    
    func shouldSaveFile(message: TransactionMessage, bubbleContainer: NSView? = nil) {
        MediaDownloader.shouldSaveFile(message: message, completion: { (success, alertMessage) in
            DispatchQueue.main.async {
                NewMessageBubbleHelper().showGenericMessageView(text: alertMessage, in: bubbleContainer)
            }
        })
    }
}
