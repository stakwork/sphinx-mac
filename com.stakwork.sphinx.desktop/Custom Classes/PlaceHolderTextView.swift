//
//  PlaceHolderTextView.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 15/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol MessageFieldDelegate: AnyObject {
    func textDidChange(_ notification: Notification)
}

final class PlaceHolderTextView: NSTextView {
    
    weak var fieldDelegate: MessageFieldDelegate?
    
    let enterKeyCodes: [UInt16] = [76, 36]
    
    @IBInspectable
    var lineBreakEnable: Bool = false
    
    private var placeholderAttributedString: NSAttributedString? = NSAttributedString(string: "")
    private var placeholderInsets = NSEdgeInsets(top: -2.0, left: 4.0, bottom: 0.0, right: 4.0)

    override func becomeFirstResponder() -> Bool {
        self.needsDisplay = true
        return super.becomeFirstResponder()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard string.isEmpty else { return }
        placeholderAttributedString?.draw(in: dirtyRect.insetBy(placeholderInsets))
    }
    
    func setPlaceHolder(color: NSColor, font: NSFont, string: String, alignment: NSTextAlignment = NSTextAlignment.left) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        
        let attrs = [NSAttributedString.Key.foregroundColor: color,
                     NSAttributedString.Key.font: font,
                     NSAttributedString.Key.paragraphStyle: style]
        let placeholderString = NSAttributedString(string: string, attributes: attrs)
        self.placeholderAttributedString = placeholderString
    }
    
    var contentSize: CGSize {
        get {
            guard let layoutManager = layoutManager, let textContainer = textContainer else {
                return self.frame.size
            }

            layoutManager.ensureLayout(for: textContainer)
            return layoutManager.usedRect(for: textContainer).size
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if lineBreakEnable && addingBreakLine(event: event) {
            fieldDelegate?.textDidChange(Notification(name: NSControl.textDidChangeNotification))
            return
        }
        super.keyDown(with: event)
    }
    
    func addingBreakLine(event: NSEvent) -> Bool {
        if enterKeyCodes.contains(event.keyCode) {
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.shift) {
                if let cursorPosition = self.cursorPosition {
                    self.string.insert("\n", at: self.string.index(self.string.startIndex, offsetBy: cursorPosition))
                    self.setSelectedRange(NSRange(location: cursorPosition + 1, length: 0))
                    return true
                }
            }
        }
        return false
    }
}

extension NSRect {
    func insetBy(_ insets: NSEdgeInsets) -> NSRect {
        return insetBy(dx: insets.left + insets.right, dy: insets.top + insets.bottom)
        .applying(CGAffineTransform(translationX: insets.left - insets.right, y: insets.top - insets.bottom))
    }
}
