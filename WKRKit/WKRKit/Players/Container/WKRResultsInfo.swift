//
//  WKRResultsInfo.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRResultsInfo: Codable {

    // MARK: - Properties

    public var playerCount: Int {
        return players.count
    }

    private var players: [WKRPlayer]
    private let points: [WKRPlayerProfile: Int]

    // MARK: Initialization

    init(players: [WKRPlayer], points: [WKRPlayerProfile: Int]) {
        self.players = players
        self.points = points
        self.players = sortedPlayers()
    }

    // MARK: - Player Order

    /**
     1. Players that found page
     2. Players that were racing when game ended
     3. Players that forfeited (no effort = no reward ;) )
     4. Players that quit

     [Below will only be shown if race still in progress (i.e. one person finished but not others)]

     5. Players that are still racing
     6. Players that are stuck in connecting phase
     */
    private func sortedPlayers() -> [WKRPlayer] {
        // The players the found the page
        let foundPagePlayers = players.filter({ $0.state == .foundPage })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.raceHistory?.duration ?? Int.max < rhs.raceHistory?.duration ?? Int.max
            })

        // The players that participated but didn't quit or forfeit
        let forcedFinishPlayers = players.filter({ $0.state == .forcedEnd })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.profile.name < rhs.profile.name
            })

        // The players that forfeited
        let forfeitedPlayers = players.filter({ $0.state == .forfeited})
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.profile.name < rhs.profile.name
            })

        // The players that quit
        let quitPlayers = players.filter({ $0.state == .quit})
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.profile.name < rhs.profile.name
            })

        // The players still racing
        let racingPlayers = players.filter({ $0.state == .racing })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.profile.name < rhs.profile.name
            })

        // The connecting players
        let connectingPlayers = players.filter({ $0.state == .connecting })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.profile.name < rhs.profile.name
            })

        // Figure out what the difference between disconnected and quit should be

        let sortedPlayers = foundPagePlayers
            + forcedFinishPlayers
            + forfeitedPlayers
            + quitPlayers
            + racingPlayers
            + connectingPlayers

        let otherPlayers = players.filter { !sortedPlayers.contains($0) }
        return sortedPlayers + otherPlayers
    }

    // MARK: - Helpers

    public func pointsInfo(at index: Int) -> (player: WKRPlayer, points: Int) {
        let player = players[index]
        if let points = points[player.profile] {
            return (player, points)
        } else {
            return (player, 0)
        }
    }

    public func player(at index: Int) -> WKRPlayer {
        return players[index]
    }

    public func player(for profile: WKRPlayerProfile) -> WKRPlayer? {
        for player in players where player.profile == profile {
            return player
        }
        return nil
    }

    public mutating func updatePlayers(_ newPlayers: [WKRPlayer]) {
        for player in newPlayers {
            if let index = players.index(of: player) {
                players[index].state = player.state
            }
        }
        players = sortedPlayers()
    }
}
