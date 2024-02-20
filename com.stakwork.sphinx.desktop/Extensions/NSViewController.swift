//
//  NSViewController.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 05/07/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Cocoa

extension NSViewController {
    func addChildVC(
        child: NSViewController,
        container: NSView
    ) {
        addChild(child)
        child.view.frame = container.bounds
        container.addSubview(child.view)
    }
    
    func removeChildVC(
        child: NSViewController
    ) {
        if let _ = child.parent {
            child.removeFromParent()
            child.view.removeFromSuperview()
        }
    }
    
    func configureVCForTesting(_ views: [NSView], identifiers: [String], _ rootView: NSView) {
        rootView.setAccessibilityChildren(views)
        views.forEach { newView in
            newView.setAccessibilityEnabled(true)
            newView.setAccessibilityRole(.window)
            let viewIdentifier = "\(identifiers[views.firstIndex(of: newView) ?? 0])"
            newView.setAccessibilityIdentifier(viewIdentifier)
        }
    }
}
