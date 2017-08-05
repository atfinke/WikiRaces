//
//  WKRPlayerProfile.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRPlayerProfile: Codable {

    // MARK: - Properties
    
    public let name: String
    public let playerID: String

    // MARK: - Initialization

    init(name: String, playerID: String) {
        self.name = name
        self.playerID = playerID
    }

}

extension WKRPlayerProfile: Hashable, Equatable {

    // MARK: - Hashable

    public var hashValue: Int {
        return playerID.hashValue
    }

    // MARK: - Equatable

    //swiftlint:disable:next operator_whitespace
    public static func ==(lhs: WKRPlayerProfile, rhs: WKRPlayerProfile) -> Bool {
        return lhs.playerID == rhs.playerID
    }

}
