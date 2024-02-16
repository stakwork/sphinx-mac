//
//  ViewController.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 10/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa
import AppKit

class SplashViewController: NSViewController {
    
    var shouldGo = true
    
    let onionConnector = SphinxOnionConnector.sharedInstance
    
    static func instantiate() -> SplashViewController {
        let viewController = StoryboardScene.Main.splashViewController.instantiate()
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DelayPerformedHelper.performAfterDelay(seconds: 1.5, completion: {
            self.goToInviteCode()
        })
    }
    
    func goToInviteCode() {
        if UserData.sharedInstance.isUserLogged() {
            goToApp()
        } else {
            let currentStep = SignupHelper.step
            switch(currentStep) {
            case SignupHelper.SignupStep.IPAndTokenSet.rawValue:
                presentInviteWelcomeViewController()
                break
            case  SignupHelper.SignupStep.InviterContactCreated.rawValue:
                presentNamePinViewController()
                break
            case SignupHelper.SignupStep.PINNameSet.rawValue:
                presentProfilePictureViewController()
                break
            case SignupHelper.SignupStep.ImageSet.rawValue:
                presentSphinxReadyViewController()
                break
            case SignupHelper.SignupStep.SphinxReady.rawValue, SignupHelper.SignupStep.SignupComplete.rawValue:
                goToApp()
                break
            default:
                presentWelcomeView()
                break
            }
        }
    }
    
    func connectTorIfNeeded() -> Bool {
        if onionConnector.usingTor() && !onionConnector.isReady() {
            presentWelcomeConnectingViewController()
            return true
        }
        return false
    }
    
    func presentWelcomeView() {
        clearAllData()
        setWindowStyleMask()
        view.window?.replaceContentBy(vc: WelcomeInitialViewController.instantiate())
    }
    
    func presentWelcomeConnectingViewController() {
        setWindowStyleMask()
        let welcomeEmptyVC = WelcomeEmptyViewController.instantiate(mode: .NewUser, viewMode: .Connecting)
        view.window?.replaceContentBy(vc: welcomeEmptyVC)
    }
    
    func presentInviteWelcomeViewController() {
        if connectTorIfNeeded() {
            return
        }
        setWindowStyleMask()
        let welcomeEmptyVC = WelcomeEmptyViewController.instantiate(mode: .NewUser, viewMode: .FriendMessage)
        view.window?.replaceContentBy(vc: welcomeEmptyVC)
    }
    
    func presentNamePinViewController() {
        if connectTorIfNeeded() {
            return
        }
        setWindowStyleMask()
        let welcomeLightningVC = WelcomeLightningViewController.instantiate(mode: .NamePin)
        view.window?.replaceContentBy(vc: welcomeLightningVC)
    }
    
    func presentProfilePictureViewController() {
        if connectTorIfNeeded() {
            return
        }
        setWindowStyleMask()
        let welcomeLightningVC = WelcomeLightningViewController.instantiate(mode: .Image)
        view.window?.replaceContentBy(vc: welcomeLightningVC)
    }
    
    func presentSphinxReadyViewController() {
        if connectTorIfNeeded() {
            return
        }
        setWindowStyleMask()
        let welcomeLightningVC = WelcomeLightningViewController.instantiate(mode: .Ready)
        view.window?.replaceContentBy(vc: welcomeLightningVC)
    }
    
    func presentSphinxMobileViewController() {
        setWindowStyleMask()
        let welcomeMobileVC = WelcomeMobileViewController.instantiate()
        view.window?.replaceContentBy(vc: welcomeMobileVC)
    }
    
    func setWindowStyleMask() {
        view.window?.styleMask = [.titled, .miniaturizable, .fullSizeContentView]
        view.window?.titlebarAppearsTransparent = true
        view.window?.titleVisibility = .hidden
    }
    
    func goToApp() {
        SplashViewController.runBackgroundProcesses()
        
        view.window?.styleMask = [.titled, .resizable, .miniaturizable]
        view.window?.titlebarAppearsTransparent = false
        view.window?.titleVisibility = .visible
        view.window?.replaceContentBy(vc: DashboardViewController.instantiate())
        
        SphinxSocketManager.sharedInstance.connectWebsocket()
    }
    
    func clearAllData() {
        UserData.sharedInstance.clearData()
        SphinxSocketManager.sharedInstance.disconnectWebsocket()
    }
    
    public static func runBackgroundProcesses() {
        DispatchQueue.global().async {
            CoreDataManager.sharedManager.deleteExpiredInvites()
            let (_, _) = EncryptionManager.sharedInstance.getOrCreateKeys()
            AttachmentsManager.sharedInstance.runAuthentication()
        }
    }
}

