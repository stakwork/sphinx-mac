//
//  NSTextField.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 14/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension NSTextField {
    
    func setPlaceHolder(color: NSColor, font: NSFont, string: String) {
        let attrs = [NSAttributedString.Key.foregroundColor: color,
                     NSAttributedString.Key.font: font]
        let placeholderString = NSAttributedString(string: string, attributes: attrs)
        self.placeholderAttributedString = placeholderString
    }
    
    func addLinksOnLabel(linkColor: NSColor = NSColor.Sphinx.PrimaryBlue, alignment: NSTextAlignment = .left) {
        let text = self.stringValue
        
        self.allowsEditingTextAttributes = true
        self.isSelectable = true
        
        let linkMatches = text.stringLinks
        let pubKeyMatches = text.pubKeyMatches
        let mentionMatches = text.mentionMatches
        
        if (linkMatches.count + pubKeyMatches.count) > 0 {
            let attributedString = NSMutableAttributedString(string: text)
            
            if let font = self.font, let color = self.textColor {
                let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = alignment
                
                attributedString.beginEditing()
                attributedString.setAttributes([NSAttributedString.Key.foregroundColor: color,
                                                NSAttributedString.Key.font: font,
                                                NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSMakeRange(0, self.stringValue.count))
                
                for match in linkMatches {
                    if let stringRange = Range(match.range) {
                        let url = text[stringRange]
                        
                        attributedString.addAttributes([NSAttributedString.Key.foregroundColor: linkColor, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.init("custom_link") : url], range: match.range)
                    }
                }
                
                for match in pubKeyMatches {
                    if let stringRange = Range(match.range) {
                        let pubkey = text[stringRange]
                        
                        attributedString.addAttributes([NSAttributedString.Key.foregroundColor: linkColor, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.init("user_pub_key") : pubkey], range: match.range)
                    }
                }
                
                for match in mentionMatches {
                    attributedString.addAttributes([NSAttributedString.Key.foregroundColor: linkColor], range: match.range)
                }
                
                attributedString.endEditing()
                self.attributedStringValue = attributedString
            }
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
