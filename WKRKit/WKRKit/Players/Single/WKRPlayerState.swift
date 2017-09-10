//
//  WKRPlayerState.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public enum WKRPlayerState: String, Codable {

    case foundPage
    case forcedEnd
    case forfeited
    case quit
    case racing
    case connecting
    case readyForNextRound
    case voting

    var isRacing: Bool {
        switch self {
        case .racing: return true
        default: return false
        }
    }

    public var text: String {
        switch self {
        case .foundPage: return "Found Page"
        case .forcedEnd: return "DF"
        case .forfeited: return "Forfeited"
        case .quit: return "Quit"
        case .racing: return "Racing"
        case .connecting: return "Ready"
        case .voting: return "Voting"
        default: fatalError()
        }
    }

    public var connected: Bool {
        return self != .quit || self != .connecting
    }

}
