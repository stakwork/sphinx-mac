//
//  NSColor.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 11/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension NSColor {
    
    static let colors = ["#7077FF","#DBD23C","#F57D25","#9F70FF","#9BC351","#FF3D3D","#C770FF","#62C784","#C99966","#FF70E9","#76D6CA","#ABDB50","#FF708B","#5AD7F7","#5FC455","#FF9270","#3FABFF","#56D978","#FFBA70","#5078F2","#618AFF"]
    
    enum Sphinx {
        
        public static let SphinxWhite = color("SphinxWhite")
        
        public static let Body = color("Body")
        public static let BodyInverted = color("BodyInverted")
        public static let HeaderBG = color("HeaderBG")
        public static let NewHeaderBG = color("NewHeaderBG")
        public static let ListBG = color("LightBG")
        public static let LightBG = color("LightBG")
        public static let ProfileBG = color("ProfileBG")
        
        public static let MainBottomIcons = color("MainBottomIcons")
        public static let ChatListSelected = color("ChatListSelected")
        
        public static let DashboardHeader = color("DashboardHeader")
        public static let DashboardSearch = color("DashboardSearch")
        public static let DashboardWashedOutText = color("DashboardWashedOutText")
        
        public static let PrimaryText = color("PrimaryText")
        public static let Text = color("Text")
        public static let TextInverted = color("TextInverted")
        public static let SecondaryText = color("SecondaryText")
        public static let SecondaryTextSent = color("SecondaryTextSent")
        public static let TextMessages = color("TextMessages")
        public static let PlaceholderText = color("PlaceholderText")
        
        public static let PrimaryBlue = color("PrimaryBlue")
        public static let PrimaryBlueBorder = color("PrimaryBlueBorder")
        public static let PrimaryBlueHighlighted = color("PrimaryBlueHighlighted")
        public static let PrimaryBlueFontColor = color("PrimaryBlueFontColor")
        public static let BlueTextAccent = color("BlueTextAccent")
        
        public static let Shadow = color("Shadow")
        public static let BubbleShadow = color("BubbleShadow")
        public static let Divider = color("Divider")
        public static let Divider2 = color("Divider2")
        public static let LightDivider = color("LightDivider")
        public static let SearchBorder = color("SearchBorder")
        public static let ExpiredInvoice = color("ExpiredInvoice")
        public static let AddressBookHeader = color("AddressBookHeader")
        public static let MessageOptionDivider = color("MessageOptionDivider")
        public static let ReplyDividerReceived = color("ReplyDividerReceived")
        public static let ReplyDividerSent = color("ReplyDividerSent")
        public static let SplitDividerColor = color("SplitDividerColor")
        public static let ReceivedIcon = color("ReceivedIcon")
        public static let ReceivedMsgBG = color("ReceivedMsgBG")
        public static let SentMsgBG = color("SentMsgBG")
        public static let OldReceivedMsgBG = color("OldReceivedMsgBG")
        public static let OldSentMsgBG = color("OldSentMsgBG")
        
        public static let PrimaryGreen = color("PrimaryGreen")
        public static let GreenBorder = color("GreenBorder")
        
        public static let PrimaryRed = color("PrimaryRed")
        public static let SecondaryRed = color("SecondaryRed")

        public static let TransactionBG = color("TransactionBG")
        public static let TransactionBGBorder = color("TransactionBGBorder")
        
        public static let WashedOutGreen = color("WashedOutGreen")
        public static let WashedOutReceivedText = color("WashedOutReceivedText")
        public static let WashedOutSentText = color("WashedOutSentText")
        
        public static let SentBubbleBorder = color("SentBubbleBorder")
        public static let ReceivedBubbleBorder = color("ReceivedBubbleBorder")
        
        public static let BadgeRed = color("BadgeRed")
        public static let SphinxOrange = color("SphinxOrange")
        public static let AuthorizationModalBack = color("AuthorizationModalBack")
        public static let SemitransparentText = color("SemitransparentText")
        
        public static let LinkSentColor = color("LinkSentColor")
        public static let LinkReceivedColor = color("LinkReceivedColor")
        public static let LinkSentButtonColor = color("LinkSentButtonColor")
        public static let LinkReceivedButtonColor = color("LinkReceivedButtonColor")
        
        public static let GiphyBack = color("GiphyBack")
        public static let SignupFieldBackground = color("SignupFieldBackground")
        public static let PinFieldBackground = color("PinFieldBackground")
        
        public static let ThreadOriginalMsg = color("ThreadOriginalMsg")
        public static let ThreadLastReply = color("ThreadLastReply")
        
        public static let NewMessageIndicator = color("NewMessageIndicator")
        
        public static let HighlightedText = color("HighlightedText")
        public static let HighlightedTextBackground = color("HighlightedTextBackground")
        
        public static let ChatsHeaderDivider = color("ChatsHeaderDivider")
        public static let InputBG1 = color("InputBG1")
        
        public static let PriceTagBG = color("PriceTagBG")
        public static let TextViewGreenColor = color("TextViewGreenColor")
        public static let TextViewBGColor = color("TextViewBGColor")
        public static let ActivePriceTag = color("ActivePriceTag")
        public static let SelectedMention = color("SelectedMention")
        
        private static func color(_ name: String) -> NSColor {
            return NSColor(named: NSColor.Name(name)) ?? NSColor.magenta
        }
    }
    
    private convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex: Int) {
        self.init(red: (hex >> 16) & 0xff, green: (hex >> 8) & 0xff, blue: hex & 0xff)
    }
    
    func toHexString() -> String {
        guard let rgbColor = usingColorSpace(NSColorSpace.extendedSRGB) else {
            return "FFFFFF"
        }
        let red = Int(round(rgbColor.redComponent * 0xFF))
        let green = Int(round(rgbColor.greenComponent * 0xFF))
        let blue = Int(round(rgbColor.blueComponent * 0xFF))
        let hexString = NSString(format: "#%02X%02X%02X", red, green, blue)
        return hexString as String
    }
    
    convenience init(hex: String, alpha: CGFloat = 1) {
        let trimHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let dropHash = String(trimHex.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        let hexString = trimHex.starts(with: "#") ? dropHash : trimHex
        let ui64 = UInt64(hexString, radix: 16)
        let value = ui64 != nil ? Int(ui64!) : 0
        // #RRGGBB
        var components = (
            R: CGFloat((value >> 16) & 0xff) / 255,
            G: CGFloat((value >> 08) & 0xff) / 255,
            B: CGFloat((value >> 00) & 0xff) / 255,
            a: alpha
        )
        if String(hexString).count == 8 {
            // #RRGGBBAA
            components = (
                R: CGFloat((value >> 24) & 0xff) / 255,
                G: CGFloat((value >> 16) & 0xff) / 255,
                B: CGFloat((value >> 08) & 0xff) / 255,
                a: CGFloat((value >> 00) & 0xff) / 255
            )
        }
        self.init(red: components.R, green: components.G, blue: components.B, alpha: components.a)
    }
    
    static func random() -> NSColor {
        if let colorCode = colors.randomElement() {
            return NSColor(hex: colorCode)
        }
        
        return NSColor(
           red:   .random(),
           green: .random(),
           blue:  .random(),
           alpha: 1.0
        )
    }
    
    static func getTextSelectionColor() -> NSColor {
        if #available(OSX 10.14, *) {
            if NSAppearance.current.name == .darkAqua {
                return NSColor.Sphinx.WashedOutSentText
            } else {
                return NSColor.selectedTextBackgroundColor
            }
        } else {
            return NSColor.selectedTextBackgroundColor
        }
    }
    
    static func getColorFor(key: String) -> NSColor {
        if let colorCode = UserDefaults.standard.value(forKey: key) as? String {
            return NSColor(hex: colorCode)
        } else {
            let newColor = NSColor.random()
            UserDefaults.standard.set(newColor.toHexString(), forKey: key)
            UserDefaults.standard.synchronize()
            return newColor
        }
    }
    
    static func removeColorFor(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }
}
