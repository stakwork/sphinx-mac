//
//  GroupActionMessageCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 29/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class GroupActionMessageCollectionViewItem: CommonGroupActionCollectionViewItem {
    
    static let kGroupLeaveRowHeight: CGFloat = 40.0
    
    @IBOutlet weak var groupJoinLeaveLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func configureMessage(message: TransactionMessage) {
        let groupLeaveText = message.getGroupMessageText()
        groupJoinLeaveLabel.stringValue = groupLeaveText
    }
    
    public static func getRowHeight() -> CGFloat {
        return GroupActionMessageCollectionViewItem.kGroupLeaveRowHeight
    }
    
}
