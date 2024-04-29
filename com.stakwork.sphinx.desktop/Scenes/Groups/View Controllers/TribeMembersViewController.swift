//
//  TribeMembersViewController.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 29/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

class TribeMembersViewController: NSViewController {

    static func instantiate() -> TribeMembersViewController {
        let viewController = StoryboardScene.Groups.tribeMembersViewController.instantiate()
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.setBackgroundColor(color: NSColor.Sphinx.GreenBorder)
    }
    
}
