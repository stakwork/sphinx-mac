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
        let targetIndex = self.numberOfItems(inSection: sections - 1)
        scrollToIndex(targetIndex: targetIndex, animated: animated)
    }
    
    func scrollToOffset(yPosition: CGFloat) {
        let y = (enclosingScrollView?.contentView.bounds.origin.y ?? 0)
        
        if (yPosition == y) {
            return
        }
        
        if let scrollView = self.enclosingScrollView {
            scrollView.documentYOffset = yPosition
        }
    }
    
    func scrollToIndex(
        targetIndex: Int,
        animated: Bool,
        position: NSCollectionView.ScrollPosition = .bottom
    ){
        let sections = self.numberOfSections
        if sections > 0 {
            let items = self.numberOfItems(inSection: sections - 1)
            if items > 0 {
                let targetIndexPath = IndexPath(item: targetIndex - 1, section: sections - 1)
                DispatchQueue.main.async {
                    if animated {
                        let ctx = NSAnimationContext.current
                        ctx.duration = 0.2
                        ctx.allowsImplicitAnimation = true
                    }
                    
                    if self.numberOfItems(inSection: sections - 1) > targetIndexPath.item {
                        self.animator().scrollToItems(at: [targetIndexPath], scrollPosition: position)
                    }
                }
            }
        }
    }
    
    func isAtBottom() -> Bool {
        let y = (enclosingScrollView?.contentView.bounds.origin.y ?? 0)
        let contentHeight = (bounds.height - (enclosingScrollView?.frame.size.height ?? 0)) + (enclosingScrollView?.contentInsets.bottom ?? 0)
        let difference = contentHeight - y
        
        return difference == 0
    }
    
    func getOffsetY() -> CGFloat {
        let y = (enclosingScrollView?.contentView.bounds.origin.y ?? 0)
        return y
    }
    
    func getDistanceToBottom() -> CGFloat {
        let y = (enclosingScrollView?.contentView.bounds.origin.y ?? 0)
        let contentHeight = (bounds.height - (enclosingScrollView?.frame.size.height ?? 0)) + (enclosingScrollView?.contentInsets.bottom ?? 0)
        let difference = contentHeight - y
        
        return difference
    }
    
    func shouldScrollToBottom() -> Bool {
        let y = (enclosingScrollView?.contentView.bounds.origin.y ?? 0)
        let contentHeight = (bounds.height - (enclosingScrollView?.frame.size.height ?? 0)) + (enclosingScrollView?.contentInsets.bottom ?? 0)
        let difference = contentHeight - y
        
        if difference <= 50 {
            return true
        }
        return false
    }
    
    func isClosedToBottom(yPosition: CGFloat) -> Bool {
        let contentHeight = (bounds.height - (enclosingScrollView?.frame.size.height ?? 0)) + (enclosingScrollView?.contentInsets.bottom ?? 0)
        let difference = contentHeight - yPosition
        
        if difference <= 10 {
            return true
        }
        return false
    }
}
