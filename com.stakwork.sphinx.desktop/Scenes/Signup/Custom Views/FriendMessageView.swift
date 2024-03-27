//
//  FriendMessageView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 10/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SwiftyJSON

class FriendMessageView: NSView, LoadableNib {
    
    weak var delegate: WelcomeEmptyViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var friendName: NSTextField!
    @IBOutlet weak var friendMessage: NSTextField!
    @IBOutlet weak var continueButtonView: SignupButtonView!
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var initialsCircle: NSBox!
    @IBOutlet weak var initialsLabel: NSTextField!
    
    var isSphinxV2 = false
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [continueButtonView.getButton()])
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    init(
        frame frameRect: NSRect,
        delegate: WelcomeEmptyViewDelegate,
        isSphinxV2: Bool = false
    ) {
        super.init(frame: frameRect)
        
        self.delegate = delegate
        self.isSphinxV2 = isSphinxV2
        
        loadViewFromNib()
        configureView()
    }
    
    func configureView() {
        continueButtonView.configureWith(title: "get.started".localized, icon: "", tag: -1, delegate: self)
        
        if isSphinxV2, let alias = SphinxOnionManager.sharedInstance.stashedInviterAlias {
            friendName.stringValue = alias
        } else if let inviter = SignupHelper.getInviter() {
            friendName.stringValue = inviter.nickname
            friendMessage.stringValue = inviter.welcomeMessage
            initialsCircle.fillColor = NSColor.random()
            initialsLabel.stringValue = inviter.nickname.getInitialsFromName()
        }
    }
}

extension FriendMessageView : SignupButtonViewDelegate {
    func didClickButton(tag: Int) {
        loading = true
        createInviterContact()
    }
    
    func createInviterContact() {
        if isSphinxV2 {
            SignupHelper.step = SignupHelper.SignupStep.InviterContactCreated.rawValue
            self.delegate?.shouldContinueTo?(mode: -1)
            return
        }
        
        if let inviter = SignupHelper.getInviter(),
            SignupHelper.step == SignupHelper.SignupStep.IPAndTokenSet.rawValue {
            
            if let pubkey = inviter.pubkey {
                
                UserContactsHelper.createContact(
                    nickname: inviter.nickname,
                    pubKey: pubkey,
                    routeHint: inviter.routeHint,
                    callback: { (success, _) in
                        
                    if success {
                        SignupHelper.step = SignupHelper.SignupStep.InviterContactCreated.rawValue
                        self.delegate?.shouldContinueTo?(mode: -1)
                    } else {
                        self.didFailCreatingContact()
                    }
                })
            } else {
                SignupHelper.step = SignupHelper.SignupStep.InviterContactCreated.rawValue
                self.delegate?.shouldContinueTo?(mode: -1)
            }
        } else {
            delegate?.shouldContinueTo?(mode: -1)
        }
    }
    
    func didFailCreatingContact() {
        loading = false
        NewMessageBubbleHelper().showGenericMessageView(text: "generic.error.message".localized)
    }
}
