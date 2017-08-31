//
//  WKRConstants.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

class WKRKitConstants {

    static let quickRaceTest            = true

    static let articlesPlistName                = "WKRArticlesData"
    static let bundle                           = Bundle(identifier: "com.andrewfinke.WKRKit")

    static let pageTitleStringToReplace         = " - Wikipedia"
    static let pageTitleCharactersToRemove      = 0

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
