//
//  CommonNewMessageCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class CommonNewMessageCollectionViewitem : NSCollectionViewItem {
    
    weak var delegate: ChatCollectionViewItemDelegate!
    
    var rowIndex: Int!
    var messageId: Int?
    var originalMessageId: Int?
    
    let kChatAvatarHeight: CGFloat = 36
    
    static let kMaximumLabelBubbleWidth: CGFloat = 500
    static let kMaximumMediaBubbleWidth: CGFloat = 400
    static let kMaximumLinksBubbleWidth: CGFloat = 400
    static let kMaximumFileBubbleWidth: CGFloat = 300
    static let kMaximumPodcastBoostBubbleWidth: CGFloat = 200
    static let kMaximumCallLinkBubbleWidth: CGFloat = 250
    static let kMaximumGenericFileBubbleWidth: CGFloat = 300
    static let kMaximumDirectPaymentWithMediaBubbleWidth: CGFloat = 300
    static let kMaximumDirectPaymentWithTextBubbleWidth: CGFloat = 250
    static let kMaximumDirectPaymentBubbleWidth: CGFloat = 200
    static let kMaximumWebViewBubbleWidth: CGFloat = 350
    static let kMaximumAudioBubbleWidth: CGFloat = 300
    static let kMaximumPodcastAudioBubbleWidth: CGFloat = 400
    static let kMaximumPaidTextViewBubbleWidth: CGFloat = 400
    static let kMaximumInvoiceBubbleWidth: CGFloat = 300
    static let kMaximumThreadBubbleWidth: CGFloat = 400
    
    static let kHighlightedTextVerticalExtraPadding: CGFloat = 12
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func getBubbleView() -> NSBox? {
        return nil
    }
}
