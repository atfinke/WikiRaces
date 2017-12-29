//
//  WKRRaceConfig.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

/// A race config. Lightweight object for sending out information about the race.
internal struct WKRRaceConfig: Codable {
    /// The starting page for the race
    let startingPage: WKRPage
    /// The final page for the race
    let endingPage: WKRPage

    /// Creates a new config object
    ///
    /// - Parameters:
    ///   - starting: The starting page for the race
    ///   - ending: The final page for the race
    init(starting: WKRPage, ending: WKRPage) {
        self.startingPage = starting
        self.endingPage = ending
    }
}
