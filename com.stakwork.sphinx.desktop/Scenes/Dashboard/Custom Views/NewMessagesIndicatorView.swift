//
//  NewMessagesIndicatorView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 02/10/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol NewMessagesIndicatorViewDelegate : AnyObject {
    func didTouchButton()
}

class NewMessagesIndicatorView: NSView, LoadableNib {
    
    weak var delegate: NewMessagesIndicatorViewDelegate?
    
    @IBOutlet var contentView: NSView!

    @IBOutlet weak var countLabelBox: NSBox!
    @IBOutlet weak var countLabel: NSTextField!

    @IBOutlet weak var arrowButton: CustomButton!
    
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
        arrowButton.cursor = .pointingHand
    }
    
    func configureWith(
        newMessagesCount: Int? = nil,
        hidden: Bool,
        andDelegate delegate: NewMessagesIndicatorViewDelegate? = nil
    ) {
        if let delegate = delegate {
            self.delegate = delegate
        }
        
        if let newMessagesCount = newMessagesCount {
            countLabel.stringValue = "\(newMessagesCount)"
            
            countLabel.isHidden = newMessagesCount == 0
            countLabelBox.isHidden = newMessagesCount == 0
        }
        
        self.isHidden = hidden
    }

    @IBAction func arrowButtonClicked(_ sender: Any) {
        delegate?.didTouchButton()
    }
}
