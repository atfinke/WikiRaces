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
    case foundPage
    case neededHelp
    case forfeited
    case quit

    func text(for player: WKRPlayerProfile) -> String {
        switch self {
        case .linkOnPage: return player.name + " is close"
        case .foundPage: return player.name + " found the page"
        case .neededHelp: return player.name + " needed help"
        case .forfeited: return player.name + " forfeited"
        case .quit: return player.name + " quit"
        }
    }

}
