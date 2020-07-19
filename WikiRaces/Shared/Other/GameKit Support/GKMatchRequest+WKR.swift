//
//  GKMatchRequest+WKR.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/26/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import WKRKit
import os.log

extension GKMatchRequest {

    static func hostRequest(raceCode: String, isInital: Bool) -> GKMatchRequest {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = isInital ? 2 : min(GKMatchRequest.maxPlayersAllowedForMatch(of: .peerToPeer), WKRKitConstants.current.maxGlobalRacePlayers)
        request.playerGroup = RaceCodeGenerator.playerGroup(for: raceCode)
        request.playerAttributes = 0xFFFF0000

        os_log("%{public}s: %{public}s, %{public}ld, %{public}ld-%{public}ld, %{public}ld, %{public}ld",
               log: .matchSupport,
               type: .info,
               #function,
               raceCode,
               isInital ? 1 : 0,
               request.minPlayers,
               request.maxPlayers,
               request.playerGroup,
               request.playerAttributes
        )

        return request
    }

    static func joinRequest(raceCode: String?) -> GKMatchRequest {
        let request = GKMatchRequest()
        request.minPlayers = 2
        if let code = raceCode {
            request.maxPlayers = min(GKMatchRequest.maxPlayersAllowedForMatch(of: .peerToPeer), WKRKitConstants.current.maxGlobalRacePlayers)
            request.playerGroup = RaceCodeGenerator.playerGroup(for: code)
            request.playerAttributes = 0x0000FFFF
        } else {
            request.maxPlayers = 2
            request.playerGroup = publicRacePlayerGroup()
        }

        os_log("%{public}s: %{public}s, %{public}ld-%{public}ld, %{public}ld, %{public}ld",
               log: .matchSupport,
               type: .info,
               #function,
               raceCode ?? "-",
               request.minPlayers,
               request.maxPlayers,
               request.playerGroup,
               request.playerAttributes
        )

        return request
    }

    private static func publicRacePlayerGroup() -> Int {
        return 11
    }
}
