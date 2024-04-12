//
//  DashboardPresenterViewController.swift
//  Sphinx
//
//  Created by Oko-osi Korede on 11/04/2024.
//  Copyright © 2024 Tomas Timinskas. All rights reserved.
//

import Cocoa

class DashboardPresenterViewController: NSViewController {
    
    @IBOutlet weak var mainContentView: NSView!
    weak var contentVC: NSViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.setBackgroundColor(color: NSColor.Sphinx.SecondaryRed)
    }
    
    static func instantiate() -> DashboardPresenterViewController {
        let viewController = StoryboardScene.Dashboard.dashboardPresenterViewController.instantiate()
        return viewController
    }
    
    func configurePresenterVC(_ contentVC: NSViewController?) {
        
        if let vc = self.contentVC {
            self.removeChildVC(child: vc)
        }
        self.contentVC = contentVC
        if let contentVC {
            self.addChildVC(child: contentVC, container: self.view)
        }
    }
    
    func dismissVC() {
        if let vc = self.contentVC {
            self.removeChildVC(child: vc)
        }
    }
}

class TransparentView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let view = super.hitTest(point)
        return view == self ? nil : view
    }
    
    override func mouseDown(with event: NSEvent) {
            // Do nothing to intercept the mouse event
        }
}
