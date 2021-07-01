//
//  CommonDeletedMessageCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 29/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CommonDeletedMessageCollectionViewItem: CommonChatCollectionViewItem {

    override func configureMessageRow(messageRow: TransactionMessageRow, contact: UserContact?, chat: Chat?, chatWidth: CGFloat) {
        super.configureMessageRow(messageRow: messageRow, contact: nil, chat: nil, chatWidth: 0)
        
        commonConfigurationForMessages()
    }

    public static func getRowHeight() -> CGFloat {
        return 50
    }
}
