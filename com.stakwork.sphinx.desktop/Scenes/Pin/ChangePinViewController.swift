//
//  ChangePinViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 16/02/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import Cocoa

class ChangePinViewController: NSViewController {
    
    @IBOutlet weak var changePinView: ChangePinView!
    
    var titleString = ""
    var mode = ChangePinMode.ChangeStandard
    var doneCompletion: ((String) -> ())? = nil
    
    enum ChangePinMode : Int {
        case ChangeStandard
        case SetPrivacy
        case ChangePrivacy
    }
    
    static func instantiate(mode: ChangePinMode, titleString: String = "") -> ChangePinViewController {
        let viewController = StoryboardScene.Pin.changePinViewController.instantiate()
        viewController.titleString = titleString
        viewController.mode = mode
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        changePinView.set(mode: mode, and: titleString)
        changePinView.doneCompletion = { pin in
            self.view.window?.close()
            self.doneCompletion?(pin)
        }
    }
}
