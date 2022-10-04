//
//  CreateTribeViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 03/10/2022.
//  Copyright © 2022 Tomas Timinskas. All rights reserved.
//

import Cocoa

class CreateTribeViewController: NSViewController {
    
    @IBOutlet weak var formScrollView: NSScrollView!
    
    static func instantiate() -> CreateTribeViewController {
        let viewController = StoryboardScene.Groups.createTribeViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
