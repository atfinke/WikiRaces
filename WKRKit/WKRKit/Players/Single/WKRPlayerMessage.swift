//
//  WKRPlayerMessage.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public enum WKRPlayerMessage: Int {

    case linkOnPage
    case missedLink
    case foundPage
    case neededHelp
    case forfeited
    case quit
    case onUSA

    var text: String {
        switch self {
        case .linkOnPage: return "is close"
        case .foundPage: return "found the page"
        case .neededHelp: return "needed help"
        case .forfeited: return "forfeited"
        case .quit: return "quit"
        case .missedLink: return "missed the link"
        case .onUSA: return "is on USA"
        }
    }

}
