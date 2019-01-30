//
//  DurationFormatter.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

internal struct DurationFormatter {
    private static let maxSeconds: Int = 360

    static func string(for duration: Int?, extended: Bool = false) -> String? {
        guard let duration = duration else { return nil }
        if duration > maxSeconds {
            let suffix = extended ? " Min" : " M"
            let time = duration / 60
            return time.description + suffix
        } else {
            let suffix = extended ? " Sec" : " S"
            return duration.description + suffix
        }
    }
}
