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

    public func playerReady(_ player: WKRPlayer) -> Bool {
        guard let index = players.index(of: player) else { return false }
        return players[index].state == .readyForNextRound
    }

    var isReadyForNextRound: Bool {
        for player in players where player.state != .readyForNextRound {
                return false
        }
        return true
    }
}
