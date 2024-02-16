//
//  ThreadRepliesView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 27/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ThreadRepliesView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var firstReplyContainer: NSView!
    @IBOutlet weak var firstReplyBubbleView: NSBox!
    @IBOutlet weak var firstReplyAvatarView: ChatSmallAvatarView!
    @IBOutlet weak var firstReplyAvatarOverlay: NSBox!
    
    @IBOutlet weak var secondReplyContainer: NSView!
    @IBOutlet weak var secondReplyBubbleView: NSBox!
    @IBOutlet weak var secondReplyAvatarView: ChatSmallAvatarView!
    @IBOutlet weak var secondReplyAvatarOverlay: NSBox!
    
    @IBOutlet weak var moreRepliesContainer: NSView!
    @IBOutlet weak var moreRepliesBubbleView: NSBox!
    @IBOutlet weak var moreRepliesCountView: NSBox!
    @IBOutlet weak var moreRepliesCountLabel: NSTextField!
    @IBOutlet weak var moreRepliesLabel: NSTextField!
    
    @IBOutlet weak var messageFakeContainer: NSView!
    @IBOutlet weak var messageFakeBubbleView: NSBox!
    
    static let kViewHeight1Reply: CGFloat = 29
    static let kViewHeight2Replies: CGFloat = 49
    static let kViewHeightSeveralReplies: CGFloat = 84

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
    
    func setup() {
        moreRepliesLabel.stringValue = "more-replies".localized
        
        firstReplyContainer.wantsLayer = true
        firstReplyContainer.layer?.masksToBounds = false
        
        secondReplyContainer.wantsLayer = true
        secondReplyContainer.layer?.masksToBounds = false
        
        moreRepliesContainer.wantsLayer = true
        moreRepliesContainer.layer?.masksToBounds = false
        
        messageFakeContainer.wantsLayer = true
        messageFakeContainer.layer?.masksToBounds = false
        
        firstReplyAvatarView.setInitialLabelSize(size: 11)
        firstReplyAvatarView.resetView()
        
        secondReplyAvatarView.setInitialLabelSize(size: 11)
        secondReplyAvatarView.resetView()
    }
    
    func configureWith(
        threadMessages: BubbleMessageLayoutState.ThreadMessages,
        direction: MessageTableCellState.MessageDirection
    ) {
        let firstReplySenderInfo = threadMessages.firstReplySenderInfo
        
        firstReplyAvatarView.configureForUserWith(
            color: firstReplySenderInfo.0,
            alias: firstReplySenderInfo.1,
            picture: firstReplySenderInfo.2
        )
        
        if let secondReplySenderInfo = threadMessages.secondReplySenderInfo {
            secondReplyAvatarView.configureForUserWith(
                color: secondReplySenderInfo.0,
                alias: secondReplySenderInfo.1,
                picture: secondReplySenderInfo.2
            )
            secondReplyContainer.isHidden = false
        } else {
            secondReplyContainer.isHidden = true
        }
        
        if threadMessages.moreRepliesCount > 0 {
            moreRepliesCountLabel.stringValue = "\(threadMessages.moreRepliesCount)"
            moreRepliesContainer.isHidden = false
        } else {
            moreRepliesContainer.isHidden = true
        }
        
        let isOutgoing = direction.isOutgoing()
        let threadBubbleColor = isOutgoing ? NSColor.Sphinx.ReceivedMsgBG : NSColor.Sphinx.ThreadLastReply
        messageFakeBubbleView.fillColor = threadBubbleColor
        messageFakeBubbleView.borderWidth = 0
    }
}
