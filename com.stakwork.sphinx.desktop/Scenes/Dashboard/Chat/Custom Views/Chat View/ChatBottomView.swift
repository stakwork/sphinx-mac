//
//  ChatBottomView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 07/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ChatBottomView: NSView, LoadableNib {

    @IBOutlet var contentView: NSView!

    @IBOutlet weak var messageReplyView: MessageReplyView!
    @IBOutlet weak var giphySearchView: GiphySearchView!
    @IBOutlet weak var messageFieldView: ChatMessageFieldView!
    
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
    
    func updateFieldStateFrom(
        _ chat: Chat?,
        and contact: UserContact?
    ) {
        self.isHidden = (chat == nil && contact == nil)
        
        messageFieldView.updateFieldStateFrom(
            chat,
            and: contact
        )
    }
    
}
