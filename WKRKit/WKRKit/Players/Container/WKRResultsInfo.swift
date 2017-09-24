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
        return playersSortedByState.count
    }

    private var playersSortedByState: [WKRPlayer]!
    private var playersSortedByPoints: [WKRPlayer]

    private let racePoints: [WKRPlayerProfile: Int]
    private let sessionPoints: [WKRPlayerProfile: Int]

    // MARK: Initialization

    init(players: [WKRPlayer], racePoints: [WKRPlayerProfile: Int], sessionPoints: [WKRPlayerProfile: Int]) {
        self.racePoints = racePoints

        // remove players that weren't in race
        let playerProfiles = players.map { $0.profile }
        self.sessionPoints = sessionPoints.filter { playerProfiles.contains($0.key) }
        self.playersSortedByPoints = players.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.profile.name < rhs.profile.name
        }).sorted(by: { (lhs, rhs) -> Bool in
            return sessionPoints[lhs.profile] ?? 0 > sessionPoints[rhs.profile] ?? 0
        })

        self.playersSortedByState = sortedPlayers(players: players)
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
    private func sortedPlayers(players: [WKRPlayer]) -> [WKRPlayer] {
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

    internal func raceRewardPoints(for player: WKRPlayer) -> Int {
        return racePoints[player.profile] ?? 0
    }

    // used to update history controller cells
    public func updatedPlayer(for player: WKRPlayer) -> WKRPlayer? {
        guard let updatedPlayerIndex = playersSortedByState.index(of: player) else { return nil }
        return playersSortedByState[updatedPlayerIndex]
    }

    public func raceResults(at index: Int) ->(player: WKRPlayer, playerState: WKRPlayerState) {
        let player = playersSortedByState[index]
        return (player, player.state)
    }

    public func sessionResults(at index: Int) -> (profile: WKRPlayerProfile, points: Int) {
        let player = playersSortedByPoints[index]
        return (player.profile, sessionPoints[player.profile] ?? 0)
    }

}
