//
//  NewMessageBoostView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 20/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class NewMessageBoostView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var boostIconView: NSBox!
    @IBOutlet weak var boostIcon: AspectFillNSImageView!
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var unitLabel: NSTextField!
    
    @IBOutlet weak var boostUserView1: MessageBoostImageView!
    @IBOutlet weak var boostUserView2: MessageBoostImageView!
    @IBOutlet weak var boostUserView3: MessageBoostImageView!
    
    @IBOutlet weak var boostUserCountLabel: NSTextField!
    
    static let kViewHeight: CGFloat = 42

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
        
    }
    
    func resetViews() {
        boostUserView1.isHidden = true
        boostUserView2.isHidden = true
        boostUserView3.isHidden = true
    }
    
    func configureWith(
        boosts: BubbleMessageLayoutState.Boosts,
        and bubble: BubbleMessageLayoutState.Bubble,
        isThreadHeader: Bool = false
    ) {
        resetViews()
        
        configureBoostIcon(active: bubble.direction.isOutgoing() || boosts.boostedByMe)
        configureWith(direction: bubble.direction)
        configureWith(boosts: boosts.boosts, and: bubble.direction, isThreadHeader: isThreadHeader)
        
        amountLabel.stringValue = boosts.totalAmount.formattedWithSeparator
        
        let boostsCount = boosts.boosts.count
        boostUserCountLabel.isHidden = boostsCount <= 3
        boostUserCountLabel.stringValue = "+\(boostsCount - 3)"
    }
    
    func configureWith(
        boosts: [BubbleMessageLayoutState.Boost],
        and direction: MessageTableCellState.MessageDirection,
        isThreadHeader: Bool = false
    ) {
        let nonDuplicatedBoosts = boosts.unique(selector: { $0.senderAlias == $1.senderAlias })
        
        if nonDuplicatedBoosts.count > 0 {
            boostUserView1.configureWith(boost: nonDuplicatedBoosts[0], and: direction, isThreadHeader: isThreadHeader)
        }
        
        if nonDuplicatedBoosts.count > 1 {
            boostUserView2.configureWith(boost: nonDuplicatedBoosts[1], and: direction, isThreadHeader: isThreadHeader)
        }
        
        if nonDuplicatedBoosts.count > 2 {
            boostUserView3.configureWith(boost: nonDuplicatedBoosts[2], and: direction, isThreadHeader: isThreadHeader)
        }
    }
    
    func configureBoostIcon(active: Bool) {
        boostIconView.fillColor = active ? NSColor.Sphinx.PrimaryGreen : NSColor.Sphinx.WashedOutReceivedText
        boostIcon.contentTintColor = active ? NSColor.white : NSColor.Sphinx.OldReceivedMsgBG
    }
    
    func configureWith(direction: MessageTableCellState.MessageDirection) {
        let isIncoming = direction.isIncoming()
        
        unitLabel.textColor = isIncoming ? NSColor.Sphinx.WashedOutReceivedText : NSColor.Sphinx.WashedOutSentText
        boostUserCountLabel.textColor = isIncoming ? NSColor.Sphinx.WashedOutReceivedText : NSColor.Sphinx.WashedOutSentText
        
        let size: CGFloat = isIncoming ? 11 : 16
        amountLabel.font = NSFont(name: isIncoming ? "Roboto-Regular" : "Roboto-Medium", size: size)!
        unitLabel.font = NSFont(name: "Roboto-Regular", size: size)!
    }
}
