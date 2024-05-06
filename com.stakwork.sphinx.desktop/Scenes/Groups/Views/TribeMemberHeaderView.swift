//
//  TribeMemberHeaderView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/05/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

class TribeMemberHeaderView: NSView {
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var countLabel: NSTextField!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func configureWith(
        title: String,
        count: String
    ) {
        titleLabel.stringValue = title
        countLabel.stringValue = count
    }
    
}
