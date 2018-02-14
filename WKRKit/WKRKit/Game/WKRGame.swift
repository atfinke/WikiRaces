//
//  WKRGame.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public class WKRGame {

    // MARK: - Closures

    var bonusPointsUpdated: ((Int) -> Void)?

    var allPlayersReadyForNextRound: (() -> Void)?
    var readyStatesUpdated: ((WKRReadyStates) -> Void)?

    var hostResultsCreated: ((WKRResultsInfo) -> Void)?
    var localResultsUpdated: ((WKRResultsInfo) -> Void)?

    // MARK: - Properties

    private let isSolo: Bool

    private var bonusTimer: Timer?
    private let localPlayer: WKRPlayer

    internal var players = [WKRPlayer]()

    internal var raceConfig: WKRRaceConfig?
    internal var preRaceConfig: WKRPreRaceConfig?

    internal private(set) var activeRace: WKRRace?
    internal private(set) var completedRaces = [WKRRace]()

    public internal(set) var state = WKRGameState.preMatch

    // MARK: - Initialization

    init(localPlayer: WKRPlayer, isSolo: Bool) {
        self.isSolo = isSolo
        self.localPlayer = localPlayer
    }

    // MARK: - Race Config

    internal func startRace(with config: WKRRaceConfig) {
        raceConfig = config
        activeRace = WKRRace(config: config, isSolo: isSolo)
        preRaceConfig = nil

        if localPlayer.isHost && !isSolo {
            bonusTimer?.invalidate()
            bonusTimer = Timer.scheduledTimer(withTimeInterval: WKRRaceConstants.bonusPointInterval,
                                              repeats: true) { [weak self] _ in
                                                self?.activeRace?.bonusPoints += WKRRaceConstants.bonusPointReward
                                                if let points = self?.activeRace?.bonusPoints {
                                                    self?.bonusPointsUpdated?(points)
                                                }
            }
        }

    }

    func createRaceConfig() -> WKRRaceConfig? {
        guard localPlayer.isHost else { fatalError("Local player not host") }
        return preRaceConfig?.raceConfig()
    }

    func finishedRace() {
        if var race = activeRace {
            race.linkedPagesFetcher = nil
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
        guard let player = players.first(where: ({ $0.profile == profile })) else { return }
        player.state = .quit
        checkForRaceEnd()
    }

    // MARK: - Player States

    internal func playerUpdated(_ player: WKRPlayer) {
        if let index = players.index(of: player) {
            players[index] = player
        } else {
            players.append(player)
        }
        if player.state == .foundPage {
            bonusTimer?.invalidate()
        }

        activeRace?.playerUpdated(player)
        checkForRaceEnd()

        guard state == .hostResults else {
            return
        }

        let readyStates = WKRReadyStates(players: players)
        readyStatesUpdated?(readyStates)
        if localPlayer.isHost && readyStates.isReadyForNextRound {
            allPlayersReadyForNextRound?()
        }
    }

    // MARK: - Race End

    func checkForRaceEnd() {
        var sessionPoints = [WKRPlayerProfile: Int]()
        for race in completedRaces {
            for (player, points) in race.calculatePoints() {
                if let previousPoints = sessionPoints[player] {
                    sessionPoints[player] = previousPoints + points
                } else {
                    sessionPoints[player] = points
                }
            }
        }

        let racePoints = activeRace?.calculatePoints() ?? [:]
        for (player, points) in racePoints {
            if let previousPoints = sessionPoints[player] {
                sessionPoints[player] = previousPoints + points
            } else {
                sessionPoints[player] = points
            }
        }

        let currentResults = WKRResultsInfo(players: players, racePoints: racePoints, sessionPoints: sessionPoints)
        guard let race = activeRace, localPlayer.isHost, race.shouldEnd() else {
            localResultsUpdated?(currentResults)
            return
        }

        let adjustedPlayers = players
        for player in adjustedPlayers where player.state == .racing {
            player.state = .forcedEnd
        }
        let results = WKRResultsInfo(players: adjustedPlayers, racePoints: racePoints, sessionPoints: sessionPoints)
        finishedRace()
        hostResultsCreated?(results)
    }

}
