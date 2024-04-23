//
//  NewChatHeaderView.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 23/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

protocol NewChatHeaderViewDelegate: AnyObject {
    func refreshTapped()
    func menuTapped()
}

class NewChatHeaderView: NSView, LoadableNib {
    
    weak var delegate: NewChatHeaderViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var profileImgView: NSImageView!
    @IBOutlet weak var profileName: NSTextField!
    
    @IBOutlet weak var balanceLabel: NSTextField!
    @IBOutlet weak var balanceUnitLabel: NSTextField!
    
    @IBOutlet weak var healthCheckView: HealthCheckView!
//    HealthCheckView
    @IBOutlet weak var reloadButton: CustomButton!
    @IBOutlet weak var menuButton: CustomButton!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setup()
    }
    
    private func setup() {
        reloadButton.cursor = .pointingHand
        menuButton.cursor = .pointingHand
    }
    
    func setHeaderTitle(_ profileName: String, profileImage: String, balance: String) {
        self.profileName.stringValue = profileName
        self.profileImgView.sd_setImage(with: URL(string: profileImage))
        self.balanceLabel.stringValue = balance
    }
    
    @IBAction func refreshButtonTapped(_ sender: NSButton) {
        delegate?.refreshTapped()
    }
    
    @IBAction func menuButtonTapped(_ sender: NSButton) {
        delegate?.menuTapped()
    }
    
    
}
