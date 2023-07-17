//
//  ChatTopView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 07/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ChatTopView: NSView, LoadableNib {

    @IBOutlet var contentView: NSView!

    @IBOutlet weak var chatHeaderView: ChatHeaderView!
    @IBOutlet weak var pinMessageBarView: PinMessageBarView! 
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
    }
    
    func updateViewOnTribeFetch() {
        setChatInfoOnHeader()
        updateSatsEarnedOnHeader()
        toggleWebAppIcon()
    }
    
    func setChatInfoOnHeader() {
        chatHeaderView.setChatInfo()
    }
    
    func setVolumeState() {
        chatHeaderView.setVolumeState()
    }
    
    func updateSatsEarnedOnHeader() {
        chatHeaderView.configureContributions()
    }
    
    func toggleWebAppIcon() {
        chatHeaderView.toggleWebAppIcon()
    }
    
    func configureHeaderWith(
        chat: Chat?,
        contact: UserContact?,
        andDelegate delegate: ChatHeaderViewDelegate
    ) {
        chatHeaderView.configureWith(
            chat: chat,
            contact: contact,
            delegate: delegate
        )
    }
    
    func configurePinnedMessageViewWith(
        chatId: Int,
        andDelegate delegate: PinnedMessageViewDelegate,
        completion: (() ->())? = nil
    ) {
        pinMessageBarView.configureWith(
            chatId: chatId,
            and: delegate,
            completion: completion
        )
    }
    
}
