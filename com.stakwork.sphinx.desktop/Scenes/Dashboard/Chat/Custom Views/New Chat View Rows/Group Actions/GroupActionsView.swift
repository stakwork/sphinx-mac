//
//  GroupActionsView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol GroupActionsViewDelegate: AnyObject {
    func didTapDeleteTribeButton()
    func didTapApproveRequestButton()
    func didTapRejectRequestButton()
}

class GroupActionsView: NSView, LoadableNib {

    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var groupActionMessageView: GroupActionMessageView!
    @IBOutlet weak var groupRemovedView: GroupRemovedView!
    @IBOutlet weak var groupRequestView: GroupRequestView!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        setup()
    }
    
    func setup() {}
    
    func hideAllSubviews() {
        groupActionMessageView.isHidden = true
        groupRemovedView.isHidden = true
        groupRequestView.isHidden = true
    }
    
    func configureWith(
        groupMemberNotification: NoBubbleMessageLayoutState.GroupMemberNotification
    ) {
        hideAllSubviews()
        
        groupActionMessageView.configureWith(message: groupMemberNotification.message)
        groupActionMessageView.isHidden = false
    }
    
    func configureWith(
        groupKickRemovedOrDeclined: NoBubbleMessageLayoutState.GroupKickRemovedOrDeclined,
        andDelegate delegate: GroupActionsViewDelegate?
    ) {
        hideAllSubviews()
        
        groupRemovedView.configureWith(
            message: groupKickRemovedOrDeclined.message,
            andDelegate: delegate
        )
        groupRemovedView.isHidden = false
    }
    
    func configureWith(
        groupMemberRequest: NoBubbleMessageLayoutState.GroupMemberRequest,
        andDelegate delegate: GroupActionsViewDelegate?
    ) {
        hideAllSubviews()
        
        groupRequestView.configureWith(
            status: groupMemberRequest.status,
            isActiveMember: groupMemberRequest.isActiveMember,
            senderAlias: groupMemberRequest.senderAlias,
            andDelegate: delegate
        )
        groupRequestView.isHidden = false
    }
    
}
