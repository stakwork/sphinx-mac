//
//  GroupRemovedCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 07/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

protocol GroupRowDelegate: AnyObject {
    func shouldDeleteGroup()
    func shouldApproveMember(requestMessage: TransactionMessage)
    func shouldRejectMember(requestMessage: TransactionMessage)
}

class GroupRemovedCollectionViewItem: CommonGroupActionCollectionViewItem {
    
    static let kRowHeight: CGFloat = 65.0

    @IBOutlet weak var deleteButtonBackground: NSBox!
    @IBOutlet weak var deleteButton: CustomButton!
    @IBOutlet weak var messageLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deleteButton.cursor = .pointingHand
        deleteButtonBackground.wantsLayer = true
        deleteButtonBackground.layer?.cornerRadius = 5
    }
    
    override func configureMessage(message: TransactionMessage) {
        messageLabel.stringValue = message.getGroupMessageText()
    }
    
    override func getCornerRadius() -> CGFloat {
        return 8
    }
    
    public static func getRowHeight() -> CGFloat {
       return GroupRemovedCollectionViewItem.kRowHeight
    }
    
    @IBAction func deleteButtonClicked(_ sender: Any) {
        delegate?.shouldDeleteGroup()
    }
}
