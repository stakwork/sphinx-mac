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
        referenceView.backgroundColor = .red
        self.addSubview(referenceView)
        self.bringSubviewToFront(referenceView)
        if charIndex < self.attributedStringValue.length {
            let attributes = self.attributedStringValue.attributes(at: charIndex, effectiveRange: nil)
            if let link = attributes[NSAttributedString.Key.init("custom_link")] as? String {
                if link.starts(with: "sphinx.chat://") {
                    if link.starts(with: "sphinx.chat://?action=tribe") {
                        let userInfo: [String: Any] = ["tribe_link" : link]
                        NotificationCenter.default.post(name: .onJoinTribeClick, object: nil, userInfo: userInfo)
                    } else {
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


extension NSClickGestureRecognizer {

   func didTapAttributedTextInLabel(label: NSTextField, inRange targetRange: NSRange) -> Bool {
       let indexOfCharacter = getTappedCharacterNumber(label: label)
       return NSLocationInRange(indexOfCharacter, targetRange)
   }
    
    func getTappedCharacterNumber(label: NSTextField) -> Int{
        guard let attributedText = label.attributedStringValue as? NSMutableAttributedString else { return -1 }

        let mutableStr = NSMutableAttributedString.init(attributedString: attributedText)
        mutableStr.addAttributes([NSAttributedString.Key.font : label.font!], range: NSRange.init(location: 0, length: attributedText.length))

        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: mutableStr)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.attributedStringValue.string.numberOfLines()
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                          y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                     y: locationOfTouchInLabel.y - textContainerOffset.y);
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return indexOfCharacter
    }

}

extension String {
    
    func numberOfLines() -> Int {
        return self.numberOfOccurrencesOf(string: "\n") + 1
    }

    func numberOfOccurrencesOf(string: String) -> Int {
        return self.components(separatedBy:string).count - 1
    }
}
