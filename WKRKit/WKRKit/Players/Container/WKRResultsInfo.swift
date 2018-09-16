//
//  WKRResultsInfo.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRResultsInfo: Codable {

    // MARK: - Types

    public struct WKRProfileSessionResults {
        public let profile: WKRPlayerProfile
        public let points: Int
        public let ranking: Int
        public let isTied: Bool
    }

    // MARK: - Properties

    public var playerCount: Int {
        return playersSortedByState.count
    }

    private var playersSortedByState: [WKRPlayer]!
    private var playersSortedByPoints: [WKRPlayer]

    private let racePoints: [WKRPlayerProfile: Int]
    private let sessionPoints: [WKRPlayerProfile: Int]

    // MARK: Initialization

    init(players: [WKRPlayer],
         racePoints: [WKRPlayerProfile: Int],
         sessionPoints: [WKRPlayerProfile: Int]) {
        
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
        let foundPagePlayers: [WKRPlayer] = players.filter({ $0.state == .foundPage })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.raceHistory?.duration ?? Int.max < rhs.raceHistory?.duration ?? Int.max
            })

        // The players that participated but didn't quit or forfeit
        let forcedFinishPlayers: [WKRPlayer] = players.filter({ $0.state == .forcedEnd })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.profile.name < rhs.profile.name
            })

        // The players that forfeited
        let forfeitedPlayers: [WKRPlayer] = players.filter({ $0.state == .forfeited })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.profile.name < rhs.profile.name
            })

        // The players that quit
        let quitPlayers: [WKRPlayer] = players.filter({ $0.state == .quit })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.profile.name < rhs.profile.name
            })

        // The players still racing
        let racingPlayers: [WKRPlayer] = players.filter({ $0.state == .racing })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.profile.name < rhs.profile.name
            })

        // The connecting players
        let connectingPlayers: [WKRPlayer] = players.filter({ $0.state == .connecting })
            .sorted(by: { (lhs, rhs) -> Bool in
                return lhs.profile.name < rhs.profile.name
            })

        // Figure out what the difference between disconnected and quit should be

        let sortedPlayers: [WKRPlayer] = foundPagePlayers
            + forcedFinishPlayers
            + forfeitedPlayers
            + quitPlayers
            + racingPlayers
            + connectingPlayers

        let otherPlayers: [WKRPlayer] = players.filter { !sortedPlayers.contains($0) }
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

    public func raceResults(at index: Int) -> (player: WKRPlayer, playerState: WKRPlayerState) {
        let player = playersSortedByState[index]
        return (player, player.state)
    }

    public func sessionResults(at index: Int) -> WKRProfileSessionResults {
        let player = playersSortedByPoints[index]
        let points = sessionPoints[player.profile] ?? 0

        var isTied = false
        var ranking = 1
        for otherPlayer in playersSortedByPoints.filter({ $0 != player }) {
            let otherPlayerPoints = sessionPoints[otherPlayer.profile] ?? 0
            if otherPlayerPoints > points {
                ranking += 1
            } else if otherPlayerPoints == points {
                isTied = true
            }
        }

        return WKRProfileSessionResults(profile: player.profile,
                                        points: sessionPoints[player.profile] ?? 0,
                                        ranking: ranking,
                                        isTied: isTied)
    }

    public func raceResultsPlayerProfileOrder() -> [WKRPlayerProfile] {
        return playersSortedByState.map { $0.profile }
    }

}
