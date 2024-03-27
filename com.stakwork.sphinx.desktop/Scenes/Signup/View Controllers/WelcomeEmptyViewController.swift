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
    var isSphinxV2 = false
    
    var isNewUser: Bool {
        get {
            return mode == .NewUser
        }
    }
    
    var isSwarmClaimUser : Bool{
        get {
            return mode == .SwarmClaimUser
        }
    }
    
    var token: String? = nil
    
    var subView: NSView? = nil
    var doneCompletion: ((String?) -> ())? = nil
    
    static func instantiate(
        mode: SignupHelper.SignupMode,
        viewMode: WelcomeViewMode,
        token: String? = nil,
        isSphinxV2: Bool = false
    ) -> WelcomeEmptyViewController {
        let viewController = StoryboardScene.Signup.welcomeEmptyViewController.instantiate()
        viewController.mode = mode
        viewController.viewMode = viewMode
        viewController.token = token
        viewController.isSphinxV2 = isSphinxV2
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
            subView = FriendMessageView(frame: NSRect.zero, delegate: self, isSphinxV2: isSphinxV2)
        }
        
        self.view.addSubview(subView!)
        subView!.constraintTo(view: self.view)
    }
    
    func continueProcess() {
        if viewMode == .Connecting {
            if isNewUser {
                continueSignup()
            } else if isSwarmClaimUser {
                continueWithToken()
            } else {
                continueRestore()
            }
        }
    }
    
    func continueRestore() {
        userData.getAndSaveTransportKey(forceGet: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.userData.getOrCreateHMACKey(forceGet: true) { [weak self] in
                
                API.sharedInstance.getWalletLocalAndRemote(callback: { local, remote in
                    guard let self = self else { return }
                    
                    self.shouldContinueTo(mode: WelcomeEmptyViewController.WelcomeViewMode.Welcome.rawValue)
                }, errorCallback: {
                    guard let self = self else { return }
                    
                    self.shouldGoBackToWelcome()
                })
                
            }
        }
    }
    
    func continueSignup() {
        if isSphinxV2 {
            self.shouldContinueTo(mode: WelcomeViewMode.FriendMessage.rawValue)
        } else {
            if connectTorIfNeeded() {
                return
            }
            generateTokenAndProceed(password: userData.getPassword())
        }
    }
    
    func continueWithToken() {
        if let token = self.token {
            userData.continueWithToken(
                token: token,
                completion: { [weak self] in
                    guard let self = self else { return }
                    
                    SignupHelper.step = SignupHelper.SignupStep.IPAndTokenSet.rawValue
                    self.shouldContinueTo(mode: WelcomeViewMode.FriendMessage.rawValue)
                },
                errorCompletion: {
                    claimQRError()
                }
            )
        } else {
            claimQRError()
        }
        
        func claimQRError() {
            let errorMessage = ("invalid.code.claim").localized
            
            self.messageBubbleHelper.showGenericMessageView(
                text: errorMessage,
                position: .Bottom,
                delay: 7,
                textColor: NSColor.white,
                backColor: NSColor.Sphinx.BadgeRed,
                backAlpha: 1.0,
                withLink: "https://sphinx.chat"
            )
        }
    }
    
    func generateTokenAndProceed(password: String? = nil) {
        let token = userData.getOrCreateAuthTokenForSignup()
        let pubkey = UserDefaults.Keys.ownerPubKey.get(defaultValue: "")
        generateTokenAndProceed(token: token, pubkey: pubkey, password: password)
    }
    
    func generateTokenAndProceed(
        token: String,
        pubkey: String,
        password: String? = nil
    ) {
        loadingLabel.stringValue = "wait.tor.request".localized
        generateTokenRetries = generateTokenRetries + 1
        
        userData.generateToken(
            token: token,
            pubkey: pubkey,
            password: password,
            completion: {
                SignupHelper.step = SignupHelper.SignupStep.IPAndTokenSet.rawValue
                self.shouldContinueTo(mode: WelcomeViewMode.FriendMessage.rawValue)
            }, errorCompletion: {
                self.generateTokenError(token: token, pubkey: pubkey, password: password)
            }
        )
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
    
    func shouldGoBackToWelcome() {
        UserDefaults.Keys.ownerPubKey.removeValue()
        messageBubbleHelper.showGenericMessageView(text: "generic.error.message".localized)
        
        DelayPerformedHelper.performAfterDelay(seconds: 1.5, completion: {
            self.view.window?.replaceContentBy(vc: WelcomeCodeViewController.instantiate(mode: .ExistingUser))
        })
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
            view.window?.replaceContentBy(
                vc: WelcomeLightningViewController.instantiate(
                    isSphinxV2: isSphinxV2
                )
            )
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
