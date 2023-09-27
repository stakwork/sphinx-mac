//
//  ThreadLastMessageHeader.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 27/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ThreadLastMessageHeader: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var chatAvatarView: ChatSmallAvatarView!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var dateLabel: NSTextField!
    
    static let kViewHeight: CGFloat = 36

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
    
    func configureWith(
        threadLastReply: BubbleMessageLayoutState.ThreadLastReply
    ) {
        chatAvatarView.configureForUserWith(
            color: threadLastReply.lastReplySenderInfo.0,
            alias: threadLastReply.lastReplySenderInfo.1,
            picture: threadLastReply.lastReplySenderInfo.2
        )
        
        nameLabel.stringValue = threadLastReply.lastReplySenderInfo.1
        dateLabel.stringValue = threadLastReply.timestamp
    }
    
}
