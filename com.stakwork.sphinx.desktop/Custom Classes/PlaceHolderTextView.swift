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
    func didTapUpArrow() -> Bool
    func didTapDownArrow() -> Bool
    @discardableResult func didTapTab() -> Bool
    func didTapEscape()
    func didDetectFilePaste(pasteBoard: NSPasteboard) -> Bool
}

final class PlaceHolderTextView: NSTextView {
    
    weak var fieldDelegate: MessageFieldDelegate?
    
    let enterKeyCodes: [UInt16] = [76, 36]
    let tabKey : UInt16 = 48
    let escapeKey : UInt16 = 53
    let downArrow : UInt16 = 125
    let upArrow : UInt16 = 126
    
    @IBInspectable
    var lineBreakEnable: Bool = false
    
    private var placeholderAttributedString: NSAttributedString? = NSAttributedString(string: "")
    private var placeholderInsets = NSEdgeInsets(top: 0.0, left: 4.0, bottom: 0.0, right: 4.0)

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
        else if(event.keyCode == upArrow){
            if (fieldDelegate?.didTapUpArrow() ?? false) {
                return
            }
        }
        else if(event.keyCode == downArrow){
            if (fieldDelegate?.didTapDownArrow() ?? false) {
                return
            }
        }
        else if(event.keyCode == tabKey){
            fieldDelegate?.didTapTab()
        }
        else if(event.keyCode == escapeKey){
            fieldDelegate?.didTapEscape()
        }
        else if(enterKeyCodes.contains(event.keyCode)) {
            if (fieldDelegate?.didTapTab() ?? false) {
                return
            }
        }
        super.keyDown(with: event)
    }
    
    func addingBreakLine(event: NSEvent) -> Bool {
        if enterKeyCodes.contains(event.keyCode) {
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.shift) {
                if let cursorPosition = self.cursorPosition {
                    if cursorPosition > self.string.length {
                        self.string.insert("\n", at: self.string.index(self.string.startIndex, offsetBy: self.string.length))
                        self.setSelectedRange(NSRange(location: self.string.length + 1, length: 0))
                    } else {
                        self.string.insert("\n", at: self.string.index(self.string.startIndex, offsetBy: cursorPosition))
                        self.setSelectedRange(NSRange(location: cursorPosition + 1, length: 0))
                    }
                    return true
                }
            }
        }
        return false
    }
    
    private let commandKey = NSEvent.ModifierFlags.command.rawValue

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "v":
                    if fieldDelegate?.didDetectFilePaste(pasteBoard: NSPasteboard.general) == true {
                       return true
                    }
                default:
                    break
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

extension NSRect {
    func insetBy(_ insets: NSEdgeInsets) -> NSRect {
        return insetBy(dx: insets.left + insets.right, dy: insets.top + insets.bottom)
        .applying(CGAffineTransform(translationX: insets.left - insets.right, y: insets.top - insets.bottom))
    }
}
