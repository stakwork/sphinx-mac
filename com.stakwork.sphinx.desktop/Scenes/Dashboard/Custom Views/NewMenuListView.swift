//
//  NewMenuListView.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 23/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol NewMenuListViewDelegate: AnyObject {
    func closeButtonTapped()
}

class NewMenuListView: NSView, LoadableNib {
    
    weak var delegate: NewMenuListViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var closeButton: CustomButton!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    private func setup() {
        closeButton.cursor = .pointingHand
    }
    
    @IBAction func closeButtonTapped(_ sender: NSButton) {
        delegate?.closeButtonTapped()
    }
    
}
