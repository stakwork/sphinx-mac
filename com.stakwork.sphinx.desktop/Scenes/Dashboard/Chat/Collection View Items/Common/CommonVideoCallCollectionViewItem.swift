//
//  CommonVideoCallCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonVideoCallCollectionViewItem : CommonChatCollectionViewItem {
    
    @IBOutlet weak var bubbleView: VideoCallBubbleView!
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var joinVideoCallView: JoinVideoCallView!
    
    static let kVideoCallSmallBubbleHeight: CGFloat = 160.0
    static let kVideoCallBigBubbleHeight: CGFloat = 212.0
    
    static let kVideoCallBubbleWidth: CGFloat = 250.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        
        joinVideoCallView.configure(delegate: self, link: messageRow.transactionMessage.messageContent ?? "")
    }
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false)
        lockSign.stringValue = encrypted ? "lock" : ""
    }
    
    public static func getRowHeight(messageRow: TransactionMessageRow) -> CGFloat {
        let bubbleSize = getBubbleSize(messageRow: messageRow)
        return bubbleSize.height + Constants.kBubbleTopMargin + Constants.kBubbleBottomMargin
    }
    
    public static func getBubbleSize(messageRow: TransactionMessageRow) -> CGSize {
        let mode = VideoCallHelper.getCallMode(link: messageRow.transactionMessage.messageContent ?? "")
        
        switch(mode) {
        case .Audio:
            return CGSize(width: CommonVideoCallCollectionViewItem.kVideoCallBubbleWidth, height: CommonVideoCallCollectionViewItem.kVideoCallSmallBubbleHeight)
        default:
            return CGSize(width: CommonVideoCallCollectionViewItem.kVideoCallBubbleWidth, height: CommonVideoCallCollectionViewItem.kVideoCallBigBubbleHeight)
        }
    }
}

extension CommonVideoCallCollectionViewItem : JoinCallViewDelegate {
    func didTapCopyLink() {
        if let link = messageRow?.transactionMessage.messageContent {
            let linkUrl = VoIPRequestMessage(JSONString: link)?.link ?? link
            ClipboardHelper.copyToClipboard(text: linkUrl, message: "call.link.copied.clipboard".localized)
        }
    }
    
    func didTapVideoButton() {
        if let link = messageRow?.transactionMessage.messageContent {
            delegate?.shouldStartCall(link: link, audioOnly: false)
        }
    }
    
    func didTapAudioButton() {
        if let link = messageRow?.transactionMessage.messageContent {
            delegate?.shouldStartCall(link: link, audioOnly: true)
        }
    }
}
