//
//  LinkHandlerTextField.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 03/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class MessageTextField: CCTextField, NSTextViewDelegate {
    
    var referenceView: NSTextView {
        let theRect = self.cell!.titleRect(forBounds: self.bounds)
        let modifiedRext = CGRect(x: theRect.origin.x, y: theRect.origin.y, width: theRect.width + 5, height: theRect.height + 4)
        let tv = NSTextView(frame: modifiedRext)
        tv.string = self.stringValue
        tv.font = self.font
        tv.textContainerInset = NSSize(width: -2.5, height: -2)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.28
        tv.textStorage!.addAttributes([NSAttributedString.Key.paragraphStyle : paragraphStyle], range: NSMakeRange(0, self.stringValue.count))

        return tv
    }
    
    override func mouseDown(with event: NSEvent) {
        if tappingOnLink(event: event) {
            return
        }
        super.mouseDown(with: event)
    }
    
    func tappingOnLink(event: NSEvent) -> Bool {
        let point = self.convert(event.locationInWindow, from: nil)
        let charIndex = referenceView.textContainer!.textView!.characterIndexForInsertion(at: point)
        if charIndex < self.attributedStringValue.length {
            let attributes = self.attributedStringValue.attributes(at: charIndex, effectiveRange: nil)
            if let link = attributes[NSAttributedString.Key.init("custom_link")] as? String {
                if link.starts(with: "sphinx.chat://") {
                    if link.starts(with: "sphinx.chat://?action=tribe") {
                        let userInfo: [String: Any] = ["tribe_link" : link]
                        NotificationCenter.default.post(name: .onJoinTribeClick, object: nil, userInfo: userInfo)
                    }
                    else if link.starts(with: "sphinx.chat://?action=share_content"){
                        
                    }
                    else {
                        NewMessageBubbleHelper().showGenericMessageView(text: "link.not.supported".localized)
                    }
                } else if let url = CustomSwiftLinkPreview.sharedInstance.extractURL(text: link) {
                    NSWorkspace.shared.open(url)
                }
                return true
            }

            if let pubKey = attributes[NSAttributedString.Key.init("user_pub_key")] as? String {
                let userInfo: [String: Any] = ["pub-key" : pubKey]
                NotificationCenter.default.post(name: .onPubKeyClick, object: nil, userInfo: userInfo)
                return true

            }
        }
        return false
    }
    
    func textViewDidChangeSelection(_ notification: Notification) {
        if let textView = notification.object as? NSTextView {
            textView.selectedTextAttributes = [NSAttributedString.Key.backgroundColor: color]
        }
    }
}
