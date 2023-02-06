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
}
