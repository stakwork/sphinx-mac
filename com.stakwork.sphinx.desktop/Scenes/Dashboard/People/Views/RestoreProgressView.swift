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
        messagesStartProgress: Int,
        delegate: RestoreModalViewControllerDelegate?
    ) {
        let restoringMessages = (progress >= messagesStartProgress)
        let restoreLabel = (restoringMessages ? "restoring-messages" : "restoring-content").localized
        restoreProgressLabel.stringValue = (progress == 0) ? "resume-restoring".localized : "\(restoreLabel) \(progress)%"
        restoreProgressBar.doubleValue = Double(progress) / 100
        
        continueLaterButton.isEnabled = restoringMessages
        continueLaterButtonContainer.alphaValue = restoringMessages ? 1.0 : 0.5
        
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
