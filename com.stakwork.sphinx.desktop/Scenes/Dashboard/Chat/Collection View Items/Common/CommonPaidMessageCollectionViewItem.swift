//
//  CommonPaidMessageCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonPaidMessageCollectionViewItem : CommonReplyCollectionViewItem {
    
    @IBOutlet weak var lockSign: NSTextField!
    @IBOutlet weak var bubbleView: MessageBubbleView!
    
    override func getBubbbleView() -> NSView? {
        return bubbleView
    }
    
    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: contact, chat: chat, chatWidth: chatWidth)
        
        showBubble(messageRow: messageRow, chatWidth: chatWidth)
        
        if let url = messageRow.transactionMessage.getMediaUrl(queryDB: false), (messageRow.transactionMessage.messageContent?.isEmpty ?? true) {
            loadData(url: url, messageRow: messageRow, chatWidth: chatWidth)
        }
    }
    
    func loadData(url: URL, messageRow: TransactionMessageRow, chatWidth: CGFloat) {
        MediaLoader.loadMessageData(url: url, message: messageRow.transactionMessage, completion: { messageId, message in
            if self.isDifferentRow(messageId: messageId) { return }
            self.delegate?.shouldReload?(item: self)
        }, errorCompletion: { messageId in
            if self.isDifferentRow(messageId: messageId) { return }
            self.showBubble(messageRow: messageRow, error: true, chatWidth: chatWidth)
        })
    }
    
    func showBubble(messageRow: TransactionMessageRow, error: Bool = false, chatWidth: CGFloat) {}
    
    func configureLockSign() {
        let encrypted = (messageRow?.transactionMessage.encrypted ?? false) && (messageRow?.transactionMessage.hasMediaKey() ?? false)
        lockSign.stringValue = encrypted ? "lock" : ""
    }
}
