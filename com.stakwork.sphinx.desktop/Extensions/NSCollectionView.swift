//
//  NSCollectionView.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 18/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension NSCollectionView {
    
    func registerItem(_ type: NSCollectionViewItem.Type) {
        register(type, forItemWithIdentifier: NSUserInterfaceItemIdentifier(String(describing: type)))
        register(NSNib(nibNamed: String(describing: type), bundle: Bundle.main), forItemWithIdentifier: NSUserInterfaceItemIdentifier(String(describing: type)))
    }

    func scrollToBottom(animated: Bool = true) {
        let sections = self.numberOfSections
        if sections > 0 {
            let items = self.numberOfItems(inSection: sections - 1)
            if items > 0 {
                let last = IndexPath(item: items - 1, section: sections - 1)
                DispatchQueue.main.async {
                    if animated {
                        let ctx = NSAnimationContext.current
                        ctx.duration = 0.2
                        ctx.allowsImplicitAnimation = true
                    }
                    
                    if self.numberOfItems(inSection: sections - 1) > last.item {
                        self.animator().scrollToItems(at: [last], scrollPosition: .bottom)
                    }
                }
            }
        }
    }
    
    func shouldScrollToBottom() -> Bool {
        let y = (enclosingScrollView?.contentView.bounds.origin.y ?? 0)
        let contentHeight = (bounds.height - (enclosingScrollView?.frame.size.height ?? 0))
        let difference = contentHeight - y
        
        if difference <= 600 {
            return true
        }
        return false
    }
}
