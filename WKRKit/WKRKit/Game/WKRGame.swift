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

    var bonusPointsUpdated: ((Int) -> Void)?

    var allPlayersReadyForNextRound: (() -> Void)?
    var readyStatesUpdated: ((WKRReadyStates) -> Void)?

    var hostResultsCreated: ((WKRResultsInfo) -> Void)?
    var localResultsUpdated: ((WKRResultsInfo) -> Void)?

    // MARK: - Properties

    private var bonusTimer: Timer?
    private let localPlayer: WKRPlayer

    internal var players = [WKRPlayer]()

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
        raceConfig = config
        activeRace = WKRActiveRace(config: config)
        preRaceConfig = nil

        if localPlayer.isHost {
            bonusTimer?.invalidate()
            bonusTimer = Timer.scheduledTimer(withTimeInterval: WKRRaceConstants.bonusPointInterval,
                                              repeats: true) { _ in
                                                self.activeRace?.bonusPoints += WKRRaceConstants.bonusPointReward
                                                if let points = self.activeRace?.bonusPoints {
                                                    self.bonusPointsUpdated?(points)
                                                }
            }
        }

    }

    func createRaceConfig() -> WKRRaceConfig? {
        guard localPlayer.isHost else { fatalError() }
        return preRaceConfig?.raceConfig()
    }

    func finishedRace() {
        if let race = activeRace {
            completedRaces.append(race)
        }
        activeRace = nil
        bonusTimer?.invalidate()
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

    internal func playerUpdated(_ player: WKRPlayer) {
        if let index = players.index(of: player) {
            players[index] = player
        } else {
            players.append(player)
        }
        activeRace?.playerUpdated(player)
        checkForRaceEnd()

        let readyStates = WKRReadyStates(players: players)
        readyStatesUpdated?(readyStates)
        if localPlayer.isHost && readyStates.isReadyForNextRound {
            allPlayersReadyForNextRound?()
        }
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

        let currentResults = WKRResultsInfo(isFinal: false, players: players, points: totalPoints)
        guard let race = activeRace, localPlayer.isHost, race.shouldEnd() else {
            localResultsUpdated?(currentResults)
            return
        }

        let adjustedPlayers = players
        for player in adjustedPlayers where player.state == .racing {
            player.state = .forcedEnd
        }
        let results = WKRResultsInfo(isFinal: true, players: adjustedPlayers, points: totalPoints)

        print("\n\n=========\nHOST SENDING")

        for x in 0..<results.playerCount {
            print(results.player(at: x).name + ": " + results.player(at: x).state.text + "  (\(results.player(at: x).raceHistory?.duration ?? 0))")
        }

        finishedRace()
        hostResultsCreated?(results)
    }

}
