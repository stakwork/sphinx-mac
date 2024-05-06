//
//  Constants.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 18/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

public enum MessagesSize: Int {
    case Big
    case Medium
    case Small
}

class Constants {
    
    public static var kMaxPinTimeoutValue : Int = 25
    
    public static var kMargin: CGFloat = 16.0
    
    //Fonts
    public static var kMessageFont = NSFont(name: "Roboto-Light", size: 16.0)!
    public static var kMessageHighlightedFont = NSFont(name: "Roboto-Light", size: 16)!
    public static var kEmojisFont = NSFont(name: "Roboto-Regular", size: 40.0)!
    public static let kAmountFont = NSFont(name: "Roboto-Bold", size: 16.0)!
    public static let kBoldSmallMessageFont = NSFont(name: "Roboto-Bold", size: 10.0)!
    public static var kMessagePreviewFont = NSFont(name: "Roboto-Light", size: 14.0)!
    public static var kNewMessagePreviewFont = NSFont(name: "Roboto-Bold", size: 14.0)!
    public static var kChatNameFont = NSFont(name: "Roboto-Light", size: 16.0)!
    public static var kChatNameHighlightedFont = NSFont(name: "Roboto-Bold", size: 16.0)!
    public static var kThreadHeaderFont = NSFont(name: "Roboto-Regular", size: 16.0)!
    public static var kThreadHeaderHighlightedFont = NSFont(name: "Roboto-Light", size: 16.0)!
    public static var kThreadListFont = NSFont(name: "Roboto-Regular", size: 17.0)!
    public static var kThreadListHighlightedFont = NSFont(name: "Roboto-Light", size: 17.0)!
    
    //Colors
    public static var kMessageLineHeight: CGFloat = 35
    public static let kMessageTextColor = NSColor.Sphinx.TextMessages
    public static let kEncryptionMessageColor = NSColor.Sphinx.PrimaryRed
    
    //Sizes
    public static var kChatListRowHeight: CGFloat = 70
    public static var kPictureBubbleHeight: CGFloat = 250.0
    public static var kPDFBubbleHeight: CGFloat = 150.0
    public static var kFileBubbleHeight: CGFloat = 60.0
    public static var kPaidFileBubbleHeight: CGFloat = 80.0
    public static var kFileBubbleWidth: CGFloat = 250.0
    public static var kBubbleCurveSize: CGFloat = 10
    public static var kLabelMargins: CGFloat = 20
    public static var kEmojisLabelMargins: CGFloat = 15
    public static var kPaidSentFixedTopPadding: CGFloat = 25
    
    public static var kBubbleReceivedArrowMargin: CGFloat = 4
    public static var kBubbleSentArrowMargin: CGFloat = 6
    public static var kReactionsViewHeight: CGFloat = 39
    
    public static let kBubbleTopMargin: CGFloat = 21
    public static let kBubbleBottomMargin: CGFloat = 4
    public static let kRowHeaderHeight: CGFloat = 21
    
    public static let kMinimumReceivedWidth:CGFloat = 220
    public static let kMinimumSentWidth:CGFloat = 200
    public static let kReactionsMinimumWidth:CGFloat = 220
    
    public static let kComposedBubbleMessageMargin: CGFloat = 2
    
    public static let kLinkPreviewHeight: CGFloat = 100
    public static let kLinkBubbleMaxWidth:CGFloat = 400
    
    public static let kTribeLinkPreviewHeight: CGFloat = 112
    public static let kTribeLinkSeeButtonHeight: CGFloat = 56
    
    //Positions
    public static var kChatListNamePosition: CGFloat = -12
    public static var kChatListMessagePosition: CGFloat = 13
    
    public static func setSize() {
        let size = UserDefaults.Keys.messagesSize.get(defaultValue: MessagesSize.Medium.rawValue)
        
        switch(size) {
        case MessagesSize.Small.rawValue:
            kMessageFont = NSFont(name: "Roboto-Light", size: 14.0)!
            kMessageHighlightedFont = NSFont(name: "Roboto-Light", size: 13.0)!
            kEmojisFont = NSFont(name: "Roboto-Regular", size: 30.0)!
            kMessagePreviewFont = NSFont(name: "Roboto-Light", size: 12.0)!
            kNewMessagePreviewFont = NSFont(name: "Roboto-Light", size: 12.0)!
            kChatNameFont = NSFont(name: "Roboto-Light", size: 14.0)!
            kChatNameHighlightedFont = NSFont(name: "Roboto-Bold", size: 14.0)!
            
            kMessageLineHeight = 31
            
            kChatListRowHeight = 70
            kPictureBubbleHeight = 210.0
            kBubbleCurveSize = 7
            kLabelMargins = 8
            kEmojisLabelMargins = 6
            kPaidSentFixedTopPadding = 30
            kReactionsViewHeight = 27
            
            kChatListNamePosition = -9.5
            kChatListMessagePosition = 10.5
            break
        case MessagesSize.Medium.rawValue:
            kMessageFont = NSFont(name: "Roboto-Light", size: 15.0)!
            kMessageHighlightedFont = NSFont(name: "Roboto-Light", size: 14.0)!
            kEmojisFont = NSFont(name: "Roboto-Regular", size: 35.0)!
            kMessagePreviewFont = NSFont(name: "Roboto-Light", size: 13.0)!
            kNewMessagePreviewFont = NSFont(name: "Roboto-Light", size: 13.0)!
            kChatNameFont = NSFont(name: "Roboto-Light", size: 15.0)!
            kChatNameHighlightedFont = NSFont(name: "Roboto-Bold", size: 15.0)!
            
            kMessageLineHeight = 32
            
            kChatListRowHeight = 70
            kPictureBubbleHeight = 230.0
            kBubbleCurveSize = 8
            kLabelMargins = 14
            kEmojisLabelMargins = 11.5
            kPaidSentFixedTopPadding = 25
            kReactionsViewHeight = 33
            
            kChatListNamePosition = -10.5
            kChatListMessagePosition = 11.5
            break
        case MessagesSize.Big.rawValue:
            kMessageFont = NSFont(name: "Roboto-Light", size: 16.0)!
            kMessageHighlightedFont = NSFont(name: "Roboto-Light", size: 16.0)!
            kEmojisFont = NSFont(name: "Roboto-Regular", size: 40.0)!
            kMessagePreviewFont = NSFont(name: "Roboto-Light", size: 14.0)!
            kNewMessagePreviewFont = NSFont(name: "Roboto-Light", size: 14.0)!
            kChatNameFont = NSFont(name: "Roboto-Light", size: 16.0)!
            kChatNameHighlightedFont = NSFont(name: "Roboto-Bold", size: 16.0)!
            
            kMessageLineHeight = 35
            
            kChatListRowHeight = 70
            kPictureBubbleHeight = 250.0
            kBubbleCurveSize = 10
            kLabelMargins = 20
            kEmojisLabelMargins = 15
            kPaidSentFixedTopPadding = 25
            kReactionsViewHeight = 39
            
            kChatListNamePosition = -12
            kChatListMessagePosition = 13
            break
        default:
            break
        }
    }
}

extension Constants {
    static let satoshisInBTC = 100_000_000
}
