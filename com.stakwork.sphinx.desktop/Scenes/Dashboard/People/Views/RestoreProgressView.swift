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
        progress: Int,
        delegate: RestoreModalViewControllerDelegate?
    ) {
        restoreModalsDelegate = delegate
        
        restoreProgressBar.doubleValue = Double(progress)
        
        restoreProgressLabel.stringValue = "Restoring: \(progress)%"
    }
    
    func setFinishingRestore() {
        restoreProgressLabel.stringValue = "Finishing restore..."
        continueLaterButton.isEnabled = false
    }
    
    @IBAction func finishRestoreButtonClicked(_ sender: Any) {
        restoreModalsDelegate?.didFinishRestoreManually()
    }
}
