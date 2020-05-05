//
//  WKRPlayerProfile.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRPlayerProfile: Codable, Hashable, Equatable {

    // MARK: - Properties -

    public let name: String
    public let playerID: String
    private let uuid: UUID

    // MARK: - Initalization -

    internal init(name: String, playerID: String) {
        self.name = name
        self.playerID = playerID
        self.uuid = UUID()
    }
}
