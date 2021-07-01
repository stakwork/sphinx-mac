//
//  CommonPodcastBoostCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonPodcastBoostCollectionViewItem: CommonChatCollectionViewItem {
    
    @IBOutlet weak var bubbleView: PodcastBoostBubbleView!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var boostAmountLabel: NSTextField!
    
    static let kBubbleHeight: CGFloat = 40.0
    static let kSentBubbleWidth: CGFloat = 152.0
    static let kReceivedBubbleWidth: CGFloat = 150.0
    static let kComposedBubbleMessageMargin: CGFloat = 2

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        
        configureAmount()
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false)
        lockSign.stringValue = encrypted ? "lock" : ""
    }
    
    func configureAmount() {
        let amount = messageRow?.transactionMessage?.getBoostAmount() ?? 0
        boostAmountLabel.stringValue = "\(amount)"
    }
    
    public static func getRowHeight() -> CGFloat {
        return kBubbleHeight + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin
    }
}
