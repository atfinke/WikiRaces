//
//  DurationFormatter.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

struct DurationFormatter {
    private static let maxSeconds = 300

    static func string(for duration: Int?) -> String? {
        guard let duration = duration else { return nil }
        if duration > maxSeconds {
            return (duration / 60).description + " S"
        } else {
            return duration.description + " S"
        }
    }
}
