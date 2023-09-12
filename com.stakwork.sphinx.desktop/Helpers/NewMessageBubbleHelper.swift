//
//  NewMessageBubbleHelper.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 13/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class NewMessageBubbleHelper {
    
    let labelMargin: CGFloat = 10
    let maxBubbleWidth: CGFloat = 500
    let titleLabelHeight: CGFloat = 20
    let titleLabelBottomMargin: CGFloat = 5
    
    let font = NSFont(name: "Roboto-Regular", size: 13.0)!
    let titleFont = NSFont(name: "Roboto-Bold", size: 15.0)!
    let loadingWheelContainerSize: CGFloat = 40.0
    let loadingWheelSize: CGFloat = 20.0
    var genericMessageY: CGFloat = 100.0
    
    var link: String? = nil
    
    static let messageViewTag = -1
    static let loadingViewTag = -2
    
    public enum VerticalPosition: Int {
        case Top
        case Bottom
    }
    
    func showGenericMessageView(
        text: String,
        in view: NSView? = nil,
        position: VerticalPosition = .Bottom,
        delay: Double = 1.5,
        textColor: NSColor = NSColor.Sphinx.Body,
        backColor: NSColor = NSColor.Sphinx.Text,
        backAlpha: CGFloat = 0.7,
        withLink link: String? = nil
    ) {
        
        if GroupsPinManager.sharedInstance.shouldAskForPin() {
            return
        }
        
        self.link = link
        
        let messageLabel = getGenericMessageLabel(text: text, in: view, textColor: textColor)
        let bubbleView = getGenericMessageBubbleView(label: messageLabel, centeredIn: view, position: position, backColor: backColor, backAlpha: backAlpha)
        bubbleView.addSubview(messageLabel)
        bubbleView.alphaValue = 0.0
        bubbleView.viewTag = NewMessageBubbleHelper.messageViewTag
        
        toggleGenericBubbleView(view: bubbleView, show: true)
        
        DelayPerformedHelper.performAfterDelay(seconds: delay) {
            self.toggleGenericBubbleView(view: bubbleView, show: false)
        }
    }
    
    func showLoadingWheel(text: String? = nil,
                          position: VerticalPosition = .Bottom,
                          textColor: NSColor = NSColor.Sphinx.Body,
                          backColor: NSColor = NSColor.Sphinx.Text,
                          in view: NSView? = nil) {
        
        if GroupsPinManager.sharedInstance.shouldAskForPin() {
            return
        }
        
        var label: NSTextField? = nil
        
        if let text = text {
            label = getGenericMessageLabel(text: text, textColor: textColor)
            label?.frame.origin.y = labelMargin
        }
        let view = getGenericMessageBubbleView(label: label, centeredIn: view, position: position, backColor: backColor, hasWheel: true)
        
        if let label = label {
            view.addSubview(label)
        }
        
        let labelHeight = (label?.frame.height ?? 0)
        let y = labelHeight > 0 ? labelHeight + labelMargin : 0
        let loadingWheel = getLoadingWheelView(container: view, y: y)
        
        view.addSubview(loadingWheel)
        view.alphaValue = 0.0
        view.viewTag = NewMessageBubbleHelper.loadingViewTag
        
        toggleGenericBubbleView(view: view, show: true, tag: NewMessageBubbleHelper.loadingViewTag)
    }
    
    func getLoadingWheelView(container: NSView,
                             y: CGFloat) -> NSView {
        
        let x = (container.frame.size.width / 2 - loadingWheelContainerSize / 2)
        let v = NSViewWithTag(frame: CGRect(x: x, y: y, width: loadingWheelContainerSize, height: loadingWheelContainerSize))
        
        let loadingWheelX = (v.frame.size.width / 2 - loadingWheelSize / 2)
        let loadingWheelY = (v.frame.size.height / 2 - loadingWheelSize / 2)
        let loadingWheelFrame = CGRect(x: loadingWheelX, y: loadingWheelY, width: loadingWheelSize, height: loadingWheelSize)
        
        let loadingWheel = NSProgressIndicator(frame: loadingWheelFrame)
        loadingWheel.isIndeterminate = true
        loadingWheel.style = .spinning
        loadingWheel.set(tintColor: NSColor.Sphinx.Body)
        loadingWheel.startAnimation(nil)
        
        v.addSubview(loadingWheel)
        
        return v
    }
    
    func hideLoadingWheel() {
        hideBubbleWith(tag: NewMessageBubbleHelper.loadingViewTag)
    }
    
    func hideGenericMessage() {
        hideBubbleWith(tag: NewMessageBubbleHelper.messageViewTag)
    }
    
    func hideBubbleWith(tag: Int) {
        for window in NSApplication.shared.windows {
            for v in window.contentView?.subviews ?? [] {
                if let v = v as? NSViewWithTag, v.viewTag == tag {
                    AnimationHelper.animateViewWith(duration: 0.1, animationsBlock: {
                        v.alphaValue = 0.0
                    }, completion: {
                        v.removeFromSuperview()
                    })
                }
            }
        }
    }
    
    func toggleGenericBubbleView(view: NSView,
                                 show: Bool,
                                 tag: Int = NewMessageBubbleHelper.messageViewTag) {
        
        let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first
        if let window = window {
            if show {
                for v in window.contentView?.subviews ?? [] {
                    if let v = v as? NSViewWithTag, v.viewTag == tag {
                        v.removeFromSuperview()
                        
                        window.contentView?.addSubview(view)
                        view.alphaValue = 1.0
                        return
                    }
                }
                
                window.contentView?.addSubview(view)
            }
        }
        
        AnimationHelper.animateViewWith(duration: 0.1, animationsBlock: {
            view.alphaValue = show ? 1.0 : 0.0
        }, completion: {
            if !show {
                view.removeFromSuperview()
            }
        })
    }
    
    func getWindowWith(_ identifier: String) -> NSWindow? {
        for window in NSApplication.shared.windows {
            if let window = window as? TaggedWindow {
                if window.windowIdentifier == identifier {
                    return window
                }
            }
        }
        return nil
    }
    
    func getGenericMessageBubbleView(label: NSTextField? = nil,
                                     centeredIn view: NSView? = nil,
                                     position: VerticalPosition = .Bottom,
                                     backColor: NSColor = NSColor.Sphinx.Text,
                                     hasWheel: Bool = false,
                                     backAlpha: CGFloat = 0.7) -> NSViewWithTag {
        
        let windowSize = NSApplication.shared.keyWindow?.frame.size
        let containerSize = view?.frame.size ?? (windowSize ?? CGSize(width: 1100, height: 850))
        var viewWidth = hasWheel ? loadingWheelContainerSize : 0.0
        var viewHeight = hasWheel ? loadingWheelContainerSize : 0.0
        
        if let label = label {
            let labelWidth = round(label.frame.size.width) + (labelMargin * 2)
            viewWidth = (viewWidth > labelWidth) ? viewWidth : labelWidth
            viewHeight += label.frame.size.height + (labelMargin * 2)
        }
        
        var viewAbsolutePosition: CGRect = CGRect.zero
        
        if let view = view {
            viewAbsolutePosition = view.convert(view.bounds, to: NSApplication.shared.keyWindow?.contentView)
        }
        
        let viewY = (position == .Top) ? containerSize.height - genericMessageY : genericMessageY
        let x = ((containerSize.width - viewWidth) / 2) + viewAbsolutePosition.origin.x
        let y = hasWheel ? (containerSize.height - viewHeight) / 2 : viewY
        
        viewWidth = (viewWidth > containerSize.width) ? (containerSize.width) : viewWidth

        let v = NSViewWithTag(frame: CGRect(x: x, y: y, width: viewWidth, height: viewHeight))
        v.wantsLayer = true
        v.layer?.cornerRadius = 5
        v.layer?.masksToBounds = true
        v.layer?.backgroundColor = backColor.withAlphaComponent(backAlpha).cgColor
        
        return v
    }
    
    func getGenericMessageLabel(text: String,
                                in view: NSView? = nil,
                                textColor: NSColor = NSColor.Sphinx.Body) -> NSTextField {
        
        let maxWidth = view != nil ? view!.frame.size.width : maxBubbleWidth
        
        let label = NSTextField(frame: CGRect(x: labelMargin, y: labelMargin, width: 0, height: 0))
        label.font = font
        label.textColor = textColor
        label.stringValue = text
        label.isBordered = false
        label.backgroundColor = NSColor.clear
        label.isBezeled = false
        label.isEditable = false
        label.alignment = .center
        label.frame.size = label.sizeThatFits(NSSize(width: maxWidth - (labelMargin * 2), height: .greatestFiniteMagnitude))
        
        label.addLinksOnLabel(linkColor: textColor, alignment: .center)
        
        if let _ = link {
            let click = NSClickGestureRecognizer(target: self, action: #selector(labelTapped))
            label.addGestureRecognizer(click)
        }
        
        return label
    }
    
    @objc func labelTapped() {
        if let link = link, link.stringLinks.count > 0 {
            var linkToOpen = link
            if !link.contains("http") {
                linkToOpen = "http://\(link)"
            }
            if let url = URL(string: linkToOpen) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
