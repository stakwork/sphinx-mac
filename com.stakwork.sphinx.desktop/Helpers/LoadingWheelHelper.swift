//
//  LoadingWheelHelper.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 27/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

class LoadingWheelHelper {
    
    public static func toggleLoadingWheel(loading: Bool,
                                          loadingWheel: NSProgressIndicator,
                                          color: NSColor,
                                          controls: [NSControl]) {
        
        loadingWheel.set(tintColor: color)
        loadingWheel.isHidden = loading ? false : true
        
        for control in controls {
            control.isEnabled = !loading
        }
        
        if loading {
            loadingWheel.startAnimation(nil)
        } else {
            loadingWheel.stopAnimation(nil)
        }
    }
}
