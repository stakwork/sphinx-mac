//
//  WelcomeTorConnectionViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class WelcomeTorConnectionViewController : CommonWelcomeViewController {
    
    @IBOutlet weak var loadingWheel: NSProgressIndicator!
    @IBOutlet weak var loadingLabel: NSTextField!
    
    let onionConnector = SphinxOnionConnector.sharedInstance
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    func onTorConnectionDone(success: Bool) {}
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, color: NSColor.white, controls: [])
            loadingLabel.isHidden = !loading
        }
    }
}

extension WelcomeTorConnectionViewController : SphinxOnionConnectorDelegate {
    func connectTorIfNeeded() -> Bool {        
        if onionConnector.usingTor() && !onionConnector.isReady() {
            loading = true
            
            onionConnector.startTor(delegate: self)
            return true
        }
        return false
    }
    
    func onionConnecting() {
        loadingLabel.stringValue = "establishing.tor.circuit".localized
    }

    func onionConnectionFinished() {
        onTorConnectionDone(success: true)
    }

    func onionConnectionFailed() {
        errorRestoring(message: "tor.connection.failed".localized)
        
        DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
            self.onTorConnectionDone(success: false)
        })
    }
    
    func errorRestoring(message: String) {
        loadingLabel.textColor = NSColor.Sphinx.BadgeRed
        loadingLabel.stringValue = message
        loading = true
    }
}
