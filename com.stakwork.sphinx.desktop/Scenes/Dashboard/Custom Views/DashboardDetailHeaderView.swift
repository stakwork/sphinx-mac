//
//  DashboardDetailHeaderView.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 18/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol DetailHeaderViewDelegate: AnyObject {
    func backButtonTapped()
    func closeButtonTapped()
}
class DashboardDetailHeaderView: NSView, LoadableNib {
    
    weak var delegate: DetailHeaderViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var closeButton: NSButton!
    @IBOutlet weak var backButton: NSButton!
    @IBOutlet weak var headerTitle: NSTextField!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    private func setup() {
        hideBackButton(hide: true)
    }
    
    @IBAction func backButtonTapped(_ sender: NSButton) {
        delegate?.backButtonTapped()
    }
    
    @IBAction func closeButtonTapped(_ sender: NSButton) {
        delegate?.closeButtonTapped()
    }
    
    func hideBackButton(hide: Bool) {
        backButton.isHidden = hide
    }
    
}
