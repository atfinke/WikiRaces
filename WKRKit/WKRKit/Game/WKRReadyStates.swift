//
//  WKRReadyStates.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/31/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRReadyStates: Codable {
    let players: [WKRPlayer]
    init(players: [WKRPlayer]) {
        self.players = players
    }

    public func isPlayerReady(_ player: WKRPlayer) -> Bool {
        guard let index = players.firstIndex(of: player) else { return false }
        return players[index].state == .readyForNextRound
    }

    func areAllRacePlayersReady(racePlayers: [WKRPlayer]) -> Bool {
        let relevantPlayers = players.filter({ racePlayers.contains($0) && $0.state != .quit })
        for player in relevantPlayers where player.state != .readyForNextRound {
            return false
        }
        return true
    }
}
