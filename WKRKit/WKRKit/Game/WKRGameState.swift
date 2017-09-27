//
//  WKRGameState.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

/// The state of the game
public enum WKRGameState: Int {
    /// Set when first connecting
    case preMatch
    /// Set in voting
    case voting
    /// Set when race starts
    case race
    /// Set when player finds page and/or forfeits
    case results
    /// Set when host sends final results for a race
    case hostResults
    /// Set when showing the point totals
    case points
}
