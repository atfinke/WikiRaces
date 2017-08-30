//
//  WKRPlayerState.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public enum WKRPlayerState: Int, Codable {

    case foundPage
    case forcedEnd
    case forfeited
    case quit
    case racing
    case connecting
    case disconnected

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
        case .disconnected: return "Disconnected"
        }
    }

    public var connected: Bool {
        return self != .disconnected || self != .quit || self != .connecting
    }

}
