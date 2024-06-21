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
            if let range = Range(NSRange(location: self.selectedRange.location, length: 0), in: self.string) {
                let cursorPosition = self.string.distance(from: self.string.startIndex, to: range.lowerBound)
                return cursorPosition
            }
            return 0
        }
    }
    
    var rangeLocation: Int? {
        get {
            return self.selectedRange.location
        }
    }
}
