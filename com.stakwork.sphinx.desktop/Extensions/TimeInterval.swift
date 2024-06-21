//
//  TimeInterval.swift
//  Sphinx
//
//  Created by Tomas Timinskas on 28/09/2023.
//  Copyright © 2023 Tomas Timinskas. All rights reserved.
//

import Foundation

extension TimeInterval {
    func getDayDiffString() -> String {
        let SECOND_MILLIS = 1000
        let MINUTE_MILLIS = 60 * SECOND_MILLIS
        let HOUR_MILLIS = 60 * MINUTE_MILLIS
        let DAY_MILLIS = 24 * HOUR_MILLIS

        var time = self * 1000
        if (time < 1000000000000) {
            time *= 1000
        }

        let now = Date().timeIntervalSince1970 * 1000
        if (time > now || time <= 0) {
            return "time.in-the-future".localized
        }

        let diff = Int(now - time)
        
        if (diff < MINUTE_MILLIS) { return "time.moments-ago".localized }
        else if (diff < 2 * MINUTE_MILLIS) { return "time.a-minute-ago".localized }
        else if (diff < 60 * MINUTE_MILLIS) { return String(format: "time.minutes-ago".localized, diff / MINUTE_MILLIS) }
        else if (diff < 2 * HOUR_MILLIS) { return "time.an-hour-ago".localized }
        else if (diff < 24 * HOUR_MILLIS) { return String(format: "time.hours-ago".localized, diff / HOUR_MILLIS) }
        else if (diff < 48 * HOUR_MILLIS) { return "time.yesterday".localized }
        else { return String(format: "time.days-ago".localized, diff / DAY_MILLIS) }
    }
}
