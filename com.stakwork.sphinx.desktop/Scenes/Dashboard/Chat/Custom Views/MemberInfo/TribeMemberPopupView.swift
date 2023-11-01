//
//  MemberInfoView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/05/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol TribeMemberPopupViewDelegate: AnyObject {
    func shouldGoToSendPayment()
    func shouldDismissTribeMemberPopup()
}

class TribeMemberPopupView: NSView, LoadableNib {
    
    weak var delegate: TribeMemberPopupViewDelegate?

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var memberPicture: ChatSmallAvatarView!
    @IBOutlet weak var memberAliasLabel: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        memberPicture.setInitialLabelSize(size: 30)
    }
    
    func configureFor(
        message: TransactionMessage,
        with delegate: TribeMemberPopupViewDelegate
    ) {
        self.delegate = delegate
        
        memberAliasLabel.stringValue = message.senderAlias ?? "Unknown"
        
        memberPicture.configureForSenderWith(message: message)
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        delegate?.shouldDismissTribeMemberPopup()
    }
    
    @IBAction func sendSatsButtonClicked(_ sender: Any) {
        delegate?.shouldGoToSendPayment()
    }
}
