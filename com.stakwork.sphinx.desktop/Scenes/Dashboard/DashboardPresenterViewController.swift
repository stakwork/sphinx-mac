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
    var contentVC: [NSViewController?]?
    weak var parentVC: NSViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.setBackgroundColor(color: NSColor.Sphinx.Body)
    }
    
    static func instantiate() -> DashboardPresenterViewController {
        let viewController = StoryboardScene.Dashboard.dashboardPresenterViewController.instantiate()
        return viewController
    }
    
    func configurePresenterVC(_ contentVC: NSViewController?) {
        if self.contentVC == nil {
            self.contentVC = []
        }
        self.contentVC?.append(contentVC)
        
        if let contentVC {
            self.addChildVC(child: contentVC, container: self.view)
        }
    }
    
    func dismissVC() {
        guard self.contentVC != nil && self.contentVC?.count ?? 0 > 0,
                let contentVC = self.contentVC else {
            return
        }
        contentVC.forEach { vc in
            self.removeChildVC(child: vc!)
        }
        self.contentVC?.removeAll()
    }
    
    func getParentVC() -> NSViewController? {
        return parentVC
    }
    
    func setParentVC() {
        if let contentVC, contentVC.count >= 1 {
            let parentIndex = contentVC.count - 1
            self.parentVC = contentVC[parentIndex]
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
