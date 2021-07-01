//
//  WelcomeMobileViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 12/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class WelcomeMobileViewController: CommonWelcomeViewController {

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var getItNowButtonView: SignupButtonView!
    @IBOutlet weak var skipButtonView: SignupButtonView!
    
    enum Buttons: Int {
        case GetItNow
        case Skip
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let label = "sphinx.on.phone".localized
        let boldLabels = ["sphinx.on.phone.bold".localized]
        titleLabel.attributedStringValue = String.getAttributedText(string: label, boldStrings: boldLabels, font: NSFont(name: "Roboto-Light", size: 30.0)!, boldFont: NSFont(name: "Roboto-Bold", size: 30.0)!)
        
        getItNowButtonView.configureWith(title: "get.it.now".localized.capitalized, icon: "", tag: Buttons.GetItNow.rawValue, delegate: self)
        getItNowButtonView.setColors(backgroundNormal: NSColor.clear, borderNormal: NSColor.white, borderWidthHover: 2.0, textNormal: NSColor.white, textHover: NSColor.white)
        
        skipButtonView.configureWith(title: "skip".localized.capitalized, icon: "", tag: Buttons.Skip.rawValue, delegate: self)
        skipButtonView.setColors(backgroundNormal: NSColor.white, backgroundHover: NSColor.white.withAlphaComponent(0.8), backgroundPressed: NSColor.white.withAlphaComponent(0.8), textNormal: NSColor.Sphinx.PrimaryBlue)
    }
    
    static func instantiate() -> WelcomeMobileViewController {
        let viewController = StoryboardScene.Signup.welcomeMobileViewController.instantiate()
        return viewController
    }
    
    func getItButtonClicked() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/apple-store/id1483956418?mt=8") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func skipButtonClicked() {
        SphinxSocketManager.sharedInstance.connectWebsocket(forceConnect: true)
        GroupsPinManager.sharedInstance.loginPin()
        SignupHelper.completeSignup()
        view.alphaValue = 0.0
        
        presentDashboard()
    }
}

extension WelcomeMobileViewController : SignupButtonViewDelegate {
    func didClickButton(tag: Int) {
        switch (tag) {
        case Buttons.GetItNow.rawValue:
            getItButtonClicked()
            break
        case Buttons.Skip.rawValue:
            skipButtonClicked()
            break
        default:
            break
        }
    }
}
