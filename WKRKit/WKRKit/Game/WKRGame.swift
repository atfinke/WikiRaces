//
//  WKRGame.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public class WKRGame {

    // MARK: - Closure

    var hostShouldEndRace: ((WKRResultsInfo) -> Void)?
    var currentResultsInfo: ((WKRResultsInfo) -> Void)!

    // MARK: - Properties

    private let localPlayer: WKRPlayer
    internal private(set) var players = [WKRPlayer]()

    internal var raceConfig: WKRRaceConfig?
    internal var preRaceConfig: WKRPreRaceConfig?

    internal private(set) var activeRace: WKRActiveRace?
    internal private(set) var completedRaces = [WKRActiveRace]()

    public internal(set) var state = WKRGameState.preMatch

    // MARK: - Initialization

    init(localPlayer: WKRPlayer) {
        self.localPlayer = localPlayer
    }

    // MARK: - Race Config

    internal func startRace(with config: WKRRaceConfig) {
        _debugLog(config)
        raceConfig = config
        activeRace = WKRActiveRace(config: config)
        preRaceConfig = nil
    }

    func createRaceConfig() -> WKRRaceConfig? {
        return preRaceConfig?.raceConfig()
    }

    func finishedRace() {
        if let race = activeRace {
            completedRaces.append(race)
        }
        activeRace = nil
    }

    // MARK: - Player Voting

    internal func player(_ profile: WKRPlayerProfile, votedFor page: WKRPage) {
        preRaceConfig?.voteInfo.player(profile, votedFor: page)
    }

    internal func playerDisconnected(_ profile: WKRPlayerProfile) {
        preRaceConfig?.voteInfo.playerDisconnected(profile)
        checkForRaceEnd()
    }

    // MARK: - Player States

    internal func player(_ profile: WKRPlayerProfile, stateUpdated state: WKRPlayerState) {
        for player in players where player.profile == profile {
            player.state = state
            activeRace?.playerUpdated(player)
        }
        checkForRaceEnd()
    }

    internal func playerUpdated(_ player: WKRPlayer) {
        if let index = players.index(of: player) {
            players[index] = player
        } else {
            players.append(player)
        }
        activeRace?.playerUpdated(player)
        checkForRaceEnd()
    }

    // MARK: - Race End

    func checkForRaceEnd() {
        var totalPoints = [WKRPlayerProfile: Int]()
        for race in completedRaces {
            for (player, points) in race.calculatePoints() {
                if let previousPoints = totalPoints[player] {
                    totalPoints[player] = previousPoints + points
                } else {
                    totalPoints[player] = points
                }
            }
        }

        for (player, points) in activeRace?.calculatePoints() ?? [:] {
            if let previousPoints = totalPoints[player] {
                totalPoints[player] = previousPoints + points
            } else {
                totalPoints[player] = points
            }
        }

        let results = WKRResultsInfo(players: players, points: totalPoints)
        guard let race = activeRace, localPlayer.isHost, race.shouldEnd() else {
            currentResultsInfo(results)
            return
        }

        finishedRace()
        hostShouldEndRace?(results)
    }

}
