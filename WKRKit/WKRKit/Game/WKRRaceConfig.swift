//
//  WKRRaceConfig.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

struct WKRRaceConfig: Codable {
    let startingPage: WKRPage
    let endingPage: WKRPage

    init(starting: WKRPage, ending: WKRPage) {
        self.startingPage = starting
        self.endingPage = ending
    }
}
