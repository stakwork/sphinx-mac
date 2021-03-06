//
//  RelayURLUpdateHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 24/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class RelayURLUpdateHelper : SphinxOnionConnectorDelegate {
    
    var newMessageBubbleHelper = NewMessageBubbleHelper()
    let userData = UserData.sharedInstance
    let onionConnector = SphinxOnionConnector.sharedInstance
    
    var view: NSView! = nil
    var doneCompletion: (() -> ())? = nil
    
    func updateRelayURL(newValue: String, view: NSView, completion: @escaping (() -> ())) {
        self.view = view
        self.doneCompletion = completion
        
        UserData.sharedInstance.save(ip: newValue)
        
        if connectTorIfNeeded() {
           return
        }
        
        verifyNewIP()
    }
    
    func verifyNewIP() {
        newMessageBubbleHelper.showLoadingWheel(text: "verifying.new.ip".localized, in: self.view)
        
        API.sharedInstance.getWalletBalance(callback: { _ in
            self.newURLConnected()
        }, errorCallback: {
            self.newURLConnectionFailed()
        })
    }
    
    func connectTorIfNeeded() -> Bool {
        if onionConnector.usingTor() && !onionConnector.isReady() {
            onionConnector.startTor(delegate: self)
            return true
        }
        return false
    }
    
    func onionConnecting() {
        newMessageBubbleHelper.showLoadingWheel(text: "establishing.tor.circuit".localized, in: self.view)
    }
    
    func onionConnectionFinished() {
        verifyNewIP()
    }
    
    func onionConnectionFailed() {
        newURLConnectionFailed()
    }
    
    func newURLConnected() {
        UserDefaults.Keys.previousIP.removeValue()
        SphinxSocketManager.sharedInstance.reconnectSocketToNewIP()
        newMessageBubbleHelper.hideLoadingWheel()
        newMessageBubbleHelper.showGenericMessageView(text: "server.url.updated".localized, in: self.view)
        doneCompletion?()
    }
    
    func newURLConnectionFailed() {
        userData.revertIP()
        newMessageBubbleHelper.hideLoadingWheel()
        newMessageBubbleHelper.showGenericMessageView(text: "reverting.ip".localized, in: self.view, delay: 4)
        doneCompletion?()
    }
}
