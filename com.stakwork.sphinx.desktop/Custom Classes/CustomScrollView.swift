//
//  CustomScrollView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class CustomScrollView : NSScrollView {
    
    var scrollingTimer : Timer? = nil
    var touchEndedCallback: (() -> ())? = nil
    
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
     
        scrollingTimer?.invalidate()
        scrollingTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(didFinishScrolling), userInfo: nil, repeats: false)
    }
    
    @objc func didFinishScrolling() {
        touchEndedCallback?()
    }
}
