//
//  NSTextField.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension NSTextField {
    
    func setPlaceHolder(
        color: NSColor,
        font: NSFont,
        string: String,
        lineHeight: CGFloat? = nil
    ) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineHeight ?? font.pointSize
        style.minimumLineHeight = lineHeight ?? font.pointSize
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: color,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: style
        ]
        let placeholderString = NSAttributedString(string: string, attributes: attrs)
        
        self.placeholderAttributedString = placeholderString
    }
    
    func addLinksOnLabel(linkColor: NSColor = NSColor.Sphinx.PrimaryBlue, alignment: NSTextAlignment = .left) {
        let text = self.stringValue
        let attributedString = NSMutableAttributedString(string: text)
        
        let pubKeyMatches = text.pubKeyMatches
        let mentionMatches = text.mentionMatches
        
        self.allowsEditingTextAttributes = true
        self.isSelectable = true
        
        if let font = self.font, let color = self.textColor {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = alignment
            
            attributedString.beginEditing()
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor: color,
                                            NSAttributedString.Key.font: font,
                                            NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: attributedString.length))
            
            let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = linkDetector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            
            if let matches = matches {
                for match in matches {
                    let url = (text as NSString).substring(with: match.range)
                    
                    attributedString.addAttributes([NSAttributedString.Key.foregroundColor: linkColor,
                                                    NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
                                                    NSAttributedString.Key.link: url], range: match.range)
                }
            }
            
            var ranges = pubKeyMatches.map { $0.range }
            ranges = ChatHelper.removeDuplicatedContainedFrom(urlRanges: ranges)
            
            for range in ranges {
                if let stringRange = Range(range) {
                    let pubkey = text[stringRange]
                    
                    attributedString.addAttributes([NSAttributedString.Key.foregroundColor: linkColor, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.init("user_pub_key") : pubkey], range: range)
                }
            }
            
            for match in mentionMatches {
                attributedString.addAttributes([NSAttributedString.Key.foregroundColor: linkColor], range: match.range)
            }
            
            attributedString.endEditing()
            self.attributedStringValue = attributedString
        }
    }

    
    func getStringSize(width: CGFloat? = nil, height: CGFloat? = nil, text: String, font: NSFont) -> CGSize {
        self.isBordered = false
        self.isBezeled = false
        self.isEditable = false
        self.isSelectable = true
        self.alignment = .left
        self.stringValue = text
        self.font = font
        return self.sizeThatFits(NSSize(width: width ?? .greatestFiniteMagnitude, height: height ?? .greatestFiniteMagnitude))
    }
}
