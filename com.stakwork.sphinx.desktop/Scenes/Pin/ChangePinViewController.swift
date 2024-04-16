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
    
    var mode = ChangePinMode.ChangeStandard
    var doneCompletion: ((String) -> ())? = nil
    
    enum ChangePinMode : Int {
        case ChangeStandard
        case SetPrivacy
        case ChangePrivacy
    }
    
    static func instantiate(mode: ChangePinMode) -> ChangePinViewController {
        let viewController = StoryboardScene.Pin.changePinViewController.instantiate()
        viewController.mode = mode
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        changePinView.set(mode: mode)
        changePinView.doneCompletion = { pin in
            self.doneCompletion?(pin)
        }
    }
}
