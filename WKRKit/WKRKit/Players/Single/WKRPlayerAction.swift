//
//  WKRPlayerAction.swift
//  WKRKit
//
//  Created by Andrew Finke on 12/28/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public enum WKRPlayerAction {
    case startedGame
    case neededHelp
    case voted(WKRPage)
    case state(WKRPlayerState)
    case forfeited
    case quit
    case ready
}
