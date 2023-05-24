//
//  PinNotificationView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 24/05/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class PinNotificationView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!

    @IBOutlet weak var pinStateLabel: NSTextField!
    
    public enum ViewMode {
        case MessagePinned
        case MessageUnpinned
    }
    
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
    
    func configureFor(mode: ViewMode) {
        pinStateLabel.stringValue = mode == .MessagePinned ? "message.pinned".localized : "message.unpinned".localized
        
        self.isHidden = false
        
        DelayPerformedHelper.performAfterDelay(seconds: 1.5, completion: {
            self.isHidden = true
        })
    }
}
