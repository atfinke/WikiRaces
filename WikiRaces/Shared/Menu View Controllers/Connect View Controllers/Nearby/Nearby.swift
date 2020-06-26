//
//  Nearby.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

struct Nearby {
    static let serviceType = "WKR-2020-07"
    struct Invite: Codable {
        let hostName: String
        let raceCode: String
    }
}
