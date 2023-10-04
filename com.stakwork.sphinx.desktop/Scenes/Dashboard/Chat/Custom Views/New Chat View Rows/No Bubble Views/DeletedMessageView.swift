//
//  DeletedMessageView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 12/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class DeletedMessageView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!

    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet weak var deletedMessageLabel: NSTextField!
    
    static let kViewHeight: CGFloat = 62.0
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
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
        dateLabel.wantsLayer = true
        dateLabel.layer?.backgroundColor = NSColor.Sphinx.Body.cgColor
        
        deletedMessageLabel.wantsLayer = true
        deletedMessageLabel.layer?.backgroundColor = NSColor.Sphinx.Body.cgColor
    }
    
    func configureWith(
        deleted: NoBubbleMessageLayoutState.Deleted,
        direction: MessageTableCellState.MessageDirection
    ) {
        dateLabel.alignment = direction.isIncoming() ? .left : .right
        deletedMessageLabel.alignment = direction.isIncoming() ? .left : .right
        
        dateLabel.stringValue = deleted.timestamp
    }
}
