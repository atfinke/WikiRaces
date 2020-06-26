//
//  Nearby.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import MultipeerConnectivity

struct Nearby {
    static let serviceType = "WKR-2020-07"
    static let peerID = MCPeerID(displayName: UUID().uuidString)
    struct Invite: Codable {
        let hostName: String
        let raceCode: String
    }
}
