//
//  EnterPinViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 16/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class EnterPinViewController: NSViewController {

    @IBOutlet weak var pinView: PinView!
    
    var subtitle = ""
    var mode = EnterPinMode.Launch
    var doneCompletion: ((String) -> ())? = nil
    
    var newMessageBubbleHelper = NewMessageBubbleHelper()
    
    enum EnterPinMode : Int {
        case Launch
        case Export
    }
    
    static func instantiate(mode: EnterPinMode, subtitle: String = "") -> EnterPinViewController {
        let viewController = StoryboardScene.Pin.enterPinViewController.instantiate()
        viewController.subtitle = subtitle
        viewController.mode = mode
        return viewController
    }
    
    func isLaunchMode() -> Bool {
        return mode == .Launch
    }
    
    func isExportMode() -> Bool {
        return mode == .Export
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - Configure View for Testing Purpose
        setViewForTesting()
        // MARK: - END
        
        pinView.setSubtitle(subtitle)
        pinView.doneCompletion = { pin in
            if self.isLaunchMode() && GroupsPinManager.sharedInstance.isValidPin(pin) {
                self.doneCompletion?(pin)
            } else if self.isExportMode() && pin == UserData.sharedInstance.getAppPin() {
                self.doneCompletion?(pin)
            } else {
                self.pinView.reset()
                self.newMessageBubbleHelper.showGenericMessageView(text: "invalid.pin".localized, in: self.view)
            }
        }
    }
    
    // MARK: - For Testing Purpose
    func setViewForTesting() {
        let subViews = [pinView!, pinView.pinFieldView.textField!]
        let identifiers = ["PinView", "SecureFields"]
        configureVCForTesting(subViews, identifiers: identifiers, self.view)
    }
    // MARK: - End
}
