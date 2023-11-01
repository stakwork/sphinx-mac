//
//  PinView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class PinView: NSView, LoadableNib {

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var backgroundBox: NSBox!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var subtitleLabel: NSTextField!
    @IBOutlet weak var pinFieldView: SignupSecureFieldView!
    
    var doneCompletion: ((String) -> ())? = nil
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        configureView()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        loadViewFromNib()
        configureView()
    }
    
    func configureView() {
        pinFieldView.configureWith(placeHolder: "", label: "", backgroundColor: NSColor.white, color: NSColor(hex: "#909BAA"), field: .PIN, delegate: self)
    }
    
    func configureForSignup() {
        backgroundBox.fillColor = NSColor(hex: "#1A232D")
        titleLabel.textColor = NSColor.white
        subtitleLabel.textColor = NSColor.white
        
        pinFieldView.configureWith(placeHolder: "", label: "", backgroundColor: NSColor.white, color: NSColor(hex: "#909BAA"), field: .PIN, delegate: self)
    }
    
    func setSubtitle(_ subtitle: String) {
        subtitleLabel.stringValue = subtitle
    }
    
    func reset() {
        pinFieldView.getTextField().stringValue = ""
        pinFieldView.getTextField().isEnabled = true
        pinFieldView.getTextField().becomeFirstResponder()
    }
    
    func makeFieldFirstResponder() {
        self.window?.makeFirstResponder(pinFieldView.getTextField())
    }
}

extension PinView : SignupFieldViewDelegate {
    func didChangeText(text: String) {}
    
    func didConfirmPin(text: String) {
        pinFieldView.getTextField().isEnabled = false
        doneCompletion?(text)
    }
}
