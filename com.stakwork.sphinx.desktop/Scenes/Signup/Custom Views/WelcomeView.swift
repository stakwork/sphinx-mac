//
//  WelcomeView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 10/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class WelcomeView: NSView, LoadableNib {
    
    weak var delegate: WelcomeEmptyViewDelegate?
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var welcomeImageView: NSImageView!
    @IBOutlet weak var welcomeTitle: NSTextField!
    @IBOutlet weak var welcomeSubtitle: NSTextField!
    @IBOutlet weak var continueButtonView: SignupButtonView!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }
    
    init(frame frameRect: NSRect, delegate: WelcomeEmptyViewDelegate) {
        super.init(frame: frameRect)
        loadViewFromNib()
        configureView()
        
        self.delegate = delegate
    }
    
    func configureView() {
        continueButtonView.configureWith(title: "continue".localized.capitalized, icon: "", tag: -1, delegate: self)
    }
}

extension WelcomeView : SignupButtonViewDelegate {
    func didClickButton(tag: Int) {
        self.delegate?.shouldContinueTo?(mode: -1)
    }
}
