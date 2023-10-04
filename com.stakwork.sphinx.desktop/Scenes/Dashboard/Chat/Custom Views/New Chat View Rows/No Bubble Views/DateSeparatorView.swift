//
//  DateSeparator.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 19/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class DateSeparatorView: NSView, LoadableNib {
    
    @IBOutlet var contentView: NSView!

    @IBOutlet weak var dateLabel: NSTextField!
    
    static let kViewHeight: CGFloat = 30.0
    
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
    
    func configureWith(
        dateSeparator: NoBubbleMessageLayoutState.DateSeparator
    ) {
        dateLabel.stringValue = dateSeparator.timestamp
    }
    
}
