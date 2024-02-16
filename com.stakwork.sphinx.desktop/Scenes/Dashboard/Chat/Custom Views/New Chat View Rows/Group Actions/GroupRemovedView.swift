//
//  GroupRemovedView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 18/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

class GroupRemovedView: NSView, LoadableNib {
    
    weak var delegate: GroupActionsViewDelegate?
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet weak var messageLabel: NSTextField!
    @IBOutlet weak var deleteButton: CustomButton!
    
    static let kViewHeight: CGFloat = 65
    
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
        message: String,
        andDelegate delegate: GroupActionsViewDelegate?
    ) {
        self.delegate = delegate
        
        messageLabel.stringValue = message
    }
    
    @IBAction func deleteButtonClicked(_ sender: Any) {
        delegate?.didTapDeleteTribeButton()
    }
    
}
