//
//  WKRFatalError.swift
//  WKRKit
//
//  Created by Andrew Finke on 9/8/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public enum WKRFatalError: Int {
    case disconnected
    case noPeers
    case internetSpeed
    case configCreationFailed

    public var title: String {
        switch self {
        case .disconnected: return "Disconnected From Race"
        case .noPeers: return "No Racers Left"
        case .internetSpeed: return "Internet Not Reachable"
        case .configCreationFailed: return "Host Issue"
        }
    }

    public var message: String {
        switch self {
        case .disconnected: return "You are no longer connected to the host of the race."
        case .noPeers: return "There are no other players left in the game."
        case .internetSpeed: return "A fast internet connection is required to play WikiRaces."
        case .configCreationFailed: return "The host experienced an unexpected issue."
        }
    }
}
