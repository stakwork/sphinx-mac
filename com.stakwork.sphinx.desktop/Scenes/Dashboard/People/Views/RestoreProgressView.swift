//
//  RestoreProgressView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 25/01/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa

class RestoreProgressView: NSView, LoadableNib {
    
    weak var restoreModalsDelegate: RestoreModalViewControllerDelegate? = nil
    
    @IBOutlet var contentView: NSView!
    @IBOutlet weak var restoreProgressLabel: NSTextField!
    @IBOutlet weak var restoreProgressBar: NSProgressIndicator!
    @IBOutlet weak var continueLaterButtonContainer: NSBox!
    @IBOutlet weak var continueLaterButton: CustomButton!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        
        continueLaterButton.cursor = .pointingHand
        
        restoreProgressBar.minValue = 0
        restoreProgressBar.maxValue = 100
        
        continueLaterButton.isEnabled = true
    }
    
    func setProgress(
        with progress: Int,
        label: String,
        buttonEnabled: Bool,
        delegate: RestoreModalViewControllerDelegate?
    ) {
        restoreProgressLabel.stringValue = (progress == 0) ? "resume-restoring".localized : "\(label) \(progress)%"
        
        restoreProgressBar.doubleValue = Double(progress)
        
        continueLaterButton.isEnabled = buttonEnabled
        continueLaterButtonContainer.alphaValue = buttonEnabled ? 1.0 : 0.5
        
        restoreModalsDelegate = delegate
    }
    
    func setFinishingRestore() {
        restoreProgressLabel.stringValue = "Finishing restore..."
        continueLaterButton.isEnabled = false
    }
    
    @IBAction func finishRestoreButtonClicked(_ sender: Any) {
        restoreModalsDelegate?.didFinishRestoreManually()
    }
}
