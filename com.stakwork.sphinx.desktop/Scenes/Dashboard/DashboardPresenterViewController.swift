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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        listenForResize()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        NotificationCenter.default.removeObserver(self, name: NSWindow.didResizeNotification, object: nil)
    }
    
    static func instantiate() -> DashboardPresenterViewController {
        let viewController = StoryboardScene.Dashboard.dashboardPresenterViewController.instantiate()
        return viewController
    }
    
    fileprivate func listenForResize() {
        NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: nil, queue: OperationQueue.main) { [weak self] (n: Notification) in
            
            for vc in self?.contentVC ?? [] {
                if let bounds = self?.view.bounds {
                    vc?.view.frame = bounds
                }
            }
        }
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
        self.contentVC = nil
    }
}

class TransparentView: NSView {
    override func mouseDown(with event: NSEvent) {
        // Do nothing to intercept the mouse event
    }
}
