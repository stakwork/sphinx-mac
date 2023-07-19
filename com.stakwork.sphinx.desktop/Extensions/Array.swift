//
//  Array.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 06/02/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    func subarray(size: Int) -> [Element] {
        return Array(self[0 ..< Swift.min(size, count)])
    }
    
    func endSubarray(size: Int) -> [Element] {
        let start = Swift.max(count - size, 0)
        return Array(self[start ..< count])
    }
    
    func unique(selector: (Element, Element) -> Bool) -> Array<Element> {
        return reduce(Array<Element>()){
            if let last = $0.last {
                return selector(last,$1) ? $0 : $0 + [$1]
            } else {
                return [$1]
            }
        }
    }
}
