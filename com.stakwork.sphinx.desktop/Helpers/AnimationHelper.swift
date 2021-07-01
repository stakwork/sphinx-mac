//
//  AnimationHelper.swift
//  com.stakwork.sphinx.desktop
//
//  Created by Tomas Timinskas on 12/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class AnimationHelper {
    public static func animateViewWith(duration: TimeInterval, animationsBlock: @escaping () -> (), completion: (() -> ())? = nil) {
        NSAnimationContext.runAnimationGroup({context in
            context.duration = duration
            context.allowsImplicitAnimation = true
            animationsBlock()
        }, completionHandler: {
            DispatchQueue.main.async {
                completion?()
            }
        })
    }
}
