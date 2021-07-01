//
//  CustomAVPlayerView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 29/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import AVKit

class CustomAVPlayerView : AVPlayerView {
    override var layer: CALayer? {
        get { super.layer }
        set {
            newValue?.backgroundColor = NSColor.Sphinx.ListBG.cgColor
            super.layer = newValue
        }
    }
}
