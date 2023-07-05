//
//  GroupRequestCollectionViewItem.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 04/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class GroupRequestCollectionViewItem: CommonGroupActionCollectionViewItem {
    
    @IBOutlet weak var groupApprovalLabel: NSTextField!
    @IBOutlet weak var acceptButtonBox: NSBox!
    @IBOutlet weak var acceptButton: NSButton!
    @IBOutlet weak var declineButtonBox: NSBox!
    @IBOutlet weak var declineButton: NSButton!
    
    static let kRowHeight: CGFloat = 65.0
    
    public enum Button: Int {
        case Approve
        case Reject
    }
    
    var contact: UserContact? = nil
    var message: TransactionMessage? = nil
    var enabled = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        acceptButtonBox.wantsLayer = true
        acceptButtonBox.layer?.cornerRadius = acceptButtonBox.frame.size.height / 2
        
        declineButtonBox.wantsLayer = true
        declineButtonBox.layer?.cornerRadius = declineButtonBox.frame.size.height / 2
    }
    
    override func getCornerRadius() -> CGFloat {
        return 8
    }
    
    override func configureMessage(message: TransactionMessage) {
        let senderId = message.senderId
        self.contact = UserContact.getContactWith(id: senderId)
        self.message = message
        
        let activeMember = message.chat?.isActiveMember(id: senderId) ?? true
        
        let declined = message.isDeclinedRequest()
        let accepted = message.isApprovedRequest()
        let pending = !declined && !accepted
        
        setLabel(message: message, declined: declined, accepted: accepted)
        
        self.enabled = !activeMember && pending
        
        acceptButtonBox .alphaValue = declined ? 0.5 : 1.0
        acceptButton.alphaValue = declined ? 0.5 : 1.0
        declineButtonBox.alphaValue = accepted ? 0.5 : 1.0
        declineButton.alphaValue = accepted ? 0.5 : 1.0
    }
    
    func setLabel(message: TransactionMessage?, declined: Bool, accepted: Bool) {
        guard let owner = UserContact.getOwner() else {
            return
        }
        
        groupApprovalLabel.stringValue = message?.getGroupMessageText(
            owner: owner,
            contact: nil
        ) ?? ""
        
        let senderNickname = message?.getMessageSenderNickname(
            owner: owner,
            contact: nil
        ) ?? "name.unknown".localized
        
        if accepted {
            groupApprovalLabel.stringValue = String(format: "admin.request.approved".localized, senderNickname)
        } else if declined {
            groupApprovalLabel.stringValue = String(format: "admin.request.rejected".localized, senderNickname)
        }
    }
    
    public static func getRowHeight() -> CGFloat {
       return GroupRequestCollectionViewItem.kRowHeight
    }
    
    @IBAction func buttonClicked(_ sender: NSButton) {
        if !enabled {
            return
        }
        
        guard let message = self.message else {
            return
        }

        
        NewMessageBubbleHelper().showLoadingWheel()
        
        switch (sender.tag) {
        case Button.Approve.rawValue:
            delegate?.shouldApproveMember(requestMessage: message)
            break
        case Button.Reject.rawValue:
            delegate?.shouldRejectMember(requestMessage: message)
            break
        default:
            break
        }
        
        enabled = false
    }
    
}
