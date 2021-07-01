//
//  WelcomeEmptyViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa
import SwiftyJSON

@objc protocol WelcomeEmptyViewDelegate: AnyObject {
    @objc optional func shouldContinueTo(mode: Int)
}

class WelcomeEmptyViewController: WelcomeTorConnectionViewController {
    
    @IBOutlet weak var viewContainer: NSView!
    
    public enum WelcomeViewMode: Int {
        case Connecting
        case Welcome
        case FriendMessage
    }
    
    let userData = UserData.sharedInstance
    let contactsService = ContactsService()
    
    var mode: SignupHelper.SignupMode = .NewUser
    var continueMode: WelcomeViewMode? = .Connecting
    var viewMode: WelcomeViewMode = .Connecting
    
    var generateTokenRetries = 0
    
    var isNewUser: Bool {
        get {
            return mode == .NewUser
        }
    }
    
    var subView: NSView? = nil
    var doneCompletion: ((String?) -> ())? = nil
    
    static func instantiate(mode: SignupHelper.SignupMode, viewMode: WelcomeViewMode) -> WelcomeEmptyViewController {
        let viewController = StoryboardScene.Signup.welcomeEmptyViewController.instantiate()
        viewController.mode = mode
        viewController.viewMode = viewMode
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadViewForMode()
        continueProcess()
    }
    
    func loadViewForMode() {
        switch (viewMode) {
        case .Connecting:
            subView = ConnectingView(frame: NSRect.zero, delegate: self)
        case .Welcome:
            subView = WelcomeView(frame: NSRect.zero, delegate: self)
        case .FriendMessage:
            subView = FriendMessageView(frame: NSRect.zero, contactsService: contactsService, delegate: self)
        }
        
        self.view.addSubview(subView!)
        subView!.constraintTo(view: self.view)
    }
    
    func continueProcess() {
        if viewMode == .Connecting {
            if isNewUser {
                continueSignup()
            } else {
                continueRestore()
            }
        }
    }
    
    func continueRestore() {
        DelayPerformedHelper.performAfterDelay(seconds: 1.5, completion: {
            self.shouldContinueTo(mode: WelcomeEmptyViewController.WelcomeViewMode.Welcome.rawValue)
        })
    }
    
    func continueSignup() {
        if connectTorIfNeeded() {
            return
        }
        generateTokenAndProceed(password: userData.getPassword())
    }
    
    func generateTokenAndProceed(password: String? = nil) {
        let token = userData.getOrCreateAuthTokenForSignup()
        let pubkey = UserDefaults.Keys.ownerPubKey.get(defaultValue: "")
        generateTokenAndProceed(token: token, pubkey: pubkey, password: password)
    }
    
    func generateTokenAndProceed(token: String, pubkey: String, password: String? = nil) {
        loadingLabel.stringValue = "wait.tor.request".localized
        
        generateTokenRetries = generateTokenRetries + 1
        
        API.sharedInstance.generateToken(token: token, pubkey: pubkey, password: password, callback: { success in
            if success {
                self.userData.save(authToken: token)
                SignupHelper.step = SignupHelper.SignupStep.IPAndTokenSet.rawValue
                self.shouldContinueTo(mode: WelcomeViewMode.FriendMessage.rawValue)
            } else {
                self.generateTokenError(token: token, pubkey: pubkey, password: password)
            }
        }, errorCallback: {
            self.generateTokenError(token: token, pubkey: pubkey, password: password)
        })
    }
    
    func generateTokenError(token: String, pubkey: String, password: String? = nil) {
        if generateTokenRetries < 4 {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.generateTokenAndProceed(token: token, pubkey: pubkey, password: password)
            })
            return
        }
        shouldGoBack()
    }
    
    func shouldGoBack() {
        UserDefaults.Keys.ownerPubKey.removeValue()
        messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized)
        
        DelayPerformedHelper.performAfterDelay(seconds: 1.5, completion: {
            self.view.window?.replaceContentBy(vc: WelcomeCodeViewController.instantiate(mode: .NewUser))
        })
    }
    
    override func onTorConnectionDone(success: Bool) {
        if success {
            continueProcess()
        } else {
            UserData.sharedInstance.clearData()
            view.window?.replaceContentBy(vc: WelcomeCodeViewController.instantiate(mode: .NewUser))
        }
    }
}

extension WelcomeEmptyViewController : WelcomeEmptyViewDelegate {
    func shouldContinueTo(mode: Int) {
        let mode = WelcomeViewMode(rawValue: mode)
        continueMode = mode
        
        if connectTorIfNeeded() {
            return
        }
        
        switch (mode) {
        case .Welcome:
            view.window?.replaceContentBy(vc: WelcomeEmptyViewController.instantiate(mode: .ExistingUser, viewMode: mode!))
            return
        case .FriendMessage:
            view.window?.replaceContentBy(vc: WelcomeEmptyViewController.instantiate(mode: .NewUser, viewMode: mode!))
            return
        default:
            break
        }

        if isNewUser {
            view.window?.replaceContentBy(vc: WelcomeLightningViewController.instantiate(contactsService: contactsService))
        } else {
            GroupsPinManager.sharedInstance.loginPin()
            SignupHelper.completeSignup()
            SphinxSocketManager.sharedInstance.connectWebsocket()
            presentDashboard()
        }
    }
    
    func closeWindow() {
        self.view.window?.close()
    }
}
