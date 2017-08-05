//
//  WKRPlayersInfo.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
//WKRPlayersInfo
public struct WKRResultsInfo: Codable {

    // MARK: - Properties

    public var playerCount: Int {
        return players.count
    }

    internal var players: [WKRPlayer]

    // MARK: - Properties

    internal let points: [WKRPlayerProfile: Int]

    internal var keys: [WKRPlayer] {
        let foundPagePlayers = players.filter({ $0.state == .foundPage })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.raceHistory?.duration ?? Int.max < rhs.raceHistory?.duration ?? Int.max
            })
        let notRacingPlayers = players.filter({ $0.state != .foundPage && $0.state != .racing })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.raceHistory?.duration ?? Int.max < rhs.raceHistory?.duration ?? Int.max
            })
        let racingPlayers = players.filter({ $0.state == .racing })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.profile.name < rhs.profile.name
            })

        return foundPagePlayers + notRacingPlayers + racingPlayers
    }

    // MARK: - Helpers

    public func pointsInfo(at index: Int) -> (player: WKRPlayer, points: Int) {
        let player = keys[index]
        if let points = points[player.profile] {
            return (player, points)
        } else {
            return (player, 0)
        }
    }

    public func player(at index: Int) -> WKRPlayer {
        return keys[index]
    }

    public func player(for profile: WKRPlayerProfile) -> WKRPlayer? {
        for player in players where player.profile == profile {
            return player
        }
        return nil
    }

    public func updatePlayers(_ newPlayers: [WKRPlayer]) {
        for player in newPlayers {
            if let index = players.index(of: player) {
                players[index].state = player.state
            }
        }
    }
}

