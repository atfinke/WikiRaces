//
//  WKRRaceConstants.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

class WKRRaceConstants {

    static let quickRaceTest                     = true

    static let votingArticlesCount               = 8
    static let votingDuration                    = 3

    static let votingPreHoldDuration             = 1.0
    static let votingPostHoldDuration            = 1.0

    static let resultsDuration                    = 20
    static let resultsPreHoldDuration             = 5.0
    static let resultsPostHoldDuration            = 10.0

    static let pageTitleStringToReplace          = " - Wikipedia"
    static let pageTitleCharactersToRemove       = 0

    static let whatLinksHereURLString           = "https://en.m.wikipedia.org/w/index.php?title=Special:WhatLinksHere"
    static let randomURLString                  = "https://en.m.wikipedia.org/wiki/Special:Random"
    static let baseURLString                    = "https://en.m.wikipedia.org/wiki"

    static let bannedURLFragments               = [
        "/wiki/File",
        "org/wiki/Wikipedia:",
        "org/wiki/Special:",
        "org/wiki/Portal:",
        "/File:",
        "#/"
    ]
}
