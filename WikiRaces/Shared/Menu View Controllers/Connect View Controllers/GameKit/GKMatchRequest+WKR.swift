//
//  GKMatchRequest+WKR.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/26/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit

extension GKMatchRequest {

    static func hostRequest(raceCode: String, isInital: Bool) -> GKMatchRequest {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = isInital ? 2 : GKMatchRequest.maxPlayersAllowedForMatch(of: .peerToPeer) //WKRKitConstants.current.maxGlobalRacePlayers
        request.playerGroup = raceCode.hash
        request.playerAttributes = 0xFFFF0000
        return request
    }
    
    static func joinRequest(raceCode: String?) -> GKMatchRequest {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = GKMatchRequest.maxPlayersAllowedForMatch(of: .peerToPeer) //WKRKitConstants.current.maxGlobalRacePlayers
        request.playerGroup = (raceCode ?? "<GLOBAL>").hash
        if raceCode != nil {
            request.playerAttributes = 0x0000FFFF
        }
        return request
    }
    
}
