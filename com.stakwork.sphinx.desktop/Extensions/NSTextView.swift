//
//  NSTextView.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 11/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Cocoa

extension NSTextView {
    var cursorPosition: Int? {
        get {
            let cursorPosition = self.selectedRange.location
            return cursorPosition
        }
    }
}
