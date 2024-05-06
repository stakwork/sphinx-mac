//
//  GroupContactListItem.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 01/05/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SDWebImage

protocol GroupContactListItemDelegate: AnyObject {
    func deleteButtonClicked(item: NSCollectionViewItem)
    func approveButtonClicked(item: NSCollectionViewItem)
    func declineButtonClicked(item: NSCollectionViewItem)
}

class GroupContactListItem: NSCollectionViewItem {

    @IBOutlet weak var profileImage: ChatSmallAvatarView!
    @IBOutlet weak var contactName: NSTextField!
    @IBOutlet weak var initialName: NSTextField!
    @IBOutlet weak var deleteButtonContainer: NSView!
    @IBOutlet weak var deleteButton: CustomButton!
    @IBOutlet weak var divider: NSBox!
    @IBOutlet weak var actionsContainer: NSView!
    @IBOutlet weak var approveButton: CustomButton!
    @IBOutlet weak var declineButton: CustomButton!
    
    var delegate: GroupContactListItemDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        setup()
    }
    
    func setup() {
        self.view.wantsLayer = true
        self.view.layer?.masksToBounds = false
        
        approveButton.cursor = .pointingHand
        declineButton.cursor = .pointingHand
        deleteButton.cursor = .pointingHand
    }
    
    func render(
        with item: GroupContact,
        index: Int? = nil,
        isLastItem: Bool,
        itemDelegate: GroupContactListItemDelegate? = nil
    ) {
        delegate = itemDelegate
        
        let nickName = item.getName()
        
        if let char = nickName.first {
            self.initialName.stringValue = item.firstOnLetter ? "\(char)".uppercased() : ""
            self.contactName.stringValue = nickName.capitalized
            
            profileImage.configureForUserWith(
                color: item.getColor(),
                alias: item.getName(),
                picture: item.avatarUrl,
                radius: 16
            )
        }
        
        deleteButtonContainer.isHidden = item.isOwner
        divider.isHidden = isLastItem
        actionsContainer.isHidden = true
    }
    
    func renderPending(
        with item: GroupContact,
        index: Int? = nil,
        isLastItem: Bool,
        itemDelegate: GroupContactListItemDelegate? = nil
    ) {
        delegate = itemDelegate
        
        let nickName = item.getName()
        
        if let char = nickName.first {
            self.initialName.stringValue = item.firstOnLetter ? "\(char)".uppercased() : ""
            self.contactName.stringValue = nickName.capitalized
            
            profileImage.configureForUserWith(
                color: item.getColor(),
                alias: item.getName(),
                picture: item.avatarUrl,
                radius: 16
            )
        }
        
        deleteButtonContainer.isHidden = true
        divider.isHidden = isLastItem
        actionsContainer.isHidden = false
    }
    
    @IBAction func deleteTapped(_ button: NSButton) {
        delegate?.deleteButtonClicked(item: self)
    }
    
    @IBAction func approveRequestButtonClicked(_ sender: Any) {
        delegate?.approveButtonClicked(item: self)
    }
    
    @IBAction func declineRequestButtonClicked(_ sender: Any) {
        delegate?.declineButtonClicked(item: self)
    }
}
