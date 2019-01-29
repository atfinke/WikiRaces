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

    public var text: String {
        switch self {
        case .foundPage: return "Found Page"
        case .forcedEnd: return "DF"
        case .forfeited: return "Forfeited"
        case .quit: return "Quit"
        case .racing: return "Racing"
        case .connecting: return "Ready"
        case .voting: return "Voting"
        case .readyForNextRound: return "Ready"
        }
    }

    public var extendedText: String {
        switch self {
        case .foundPage: return "Found Page"
        case .forcedEnd: return "Didn't Finish"
        case .forfeited: return "Forfeited"
        case .quit: return "Quit Race"
        default: return self.text
        }
    }

}
