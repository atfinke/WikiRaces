//
//  WKRManager+Host.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

extension WKRManager {

    // MARK: - Game Updates

    func configure(game: WKRGame) {
        guard localPlayer.isHost else { fatalError("Local player not host") }

        game.allPlayersReadyForNextRound = { [weak self] in
            guard let isHost = self?.localPlayer.isHost, let gameState = self?.gameState else {
                return
            }
            if isHost && gameState == .hostResults {
                //swiftlint:disable:next line_length
                DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceDurationConstants.resultsAllReadyDelay, execute: {
                    self?.finishResultsCountdown()
                })
            }
        }
        game.bonusPointsUpdated = { [weak self] points in
            let bonusPoints = WKRCodable(int: WKRInt(type: .bonusPoints, value: points))
            self?.peerNetwork.send(object: bonusPoints)
        }
        game.hostResultsCreated = { [weak self] result in
            DispatchQueue.main.async {
                let state = WKRGameState.hostResults
                self?.peerNetwork.send(object: WKRCodable(enum: state))
                self?.peerNetwork.send(object: WKRCodable(result))
                self?.prepareResultsCountdown()
            }
        }
    }

    // MARK: - Results

    func prepareResultsCountdown() {
        guard localPlayer.isHost else { fatalError("Local player not host") }

        DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceDurationConstants.resultsPreCountdown) {
            self.startResultsCountdown()
        }
    }

    private func startResultsCountdown() {
        guard localPlayer.isHost else { fatalError("Local player not host") }

        var timeLeft = WKRRaceDurationConstants.resultsState
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in

            if self?.gameState == .points {
                timer.invalidate()
                return
            }

            timeLeft -= 1

            let resultsTime = WKRCodable(int: WKRInt(type: .resultsTime, value: timeLeft))
            self?.peerNetwork.send(object: resultsTime)

            let showReadyTime = WKRRaceDurationConstants.resultsState - WKRRaceDurationConstants.resultsShowReadyAfter

            if timeLeft <= 0 {
                self?.finishResultsCountdown()
                timer.invalidate()
            } else if timeLeft == showReadyTime {
                let showReady = WKRCodable(int: WKRInt(type: .showReady, value: 1))
                self?.peerNetwork.send(object: showReady)
            } else if timeLeft == WKRRaceDurationConstants.resultsDisableReadyBefore {
                let showReady = WKRCodable(int: WKRInt(type: .showReady, value: 0))
                self?.peerNetwork.send(object: showReady)
            }
        }
    }

    internal func finishResultsCountdown() {
        guard localPlayer.isHost && gameState != .points else { return }

        self.game.players = []
        self.peerNetwork.send(object: WKRCodable(enum: WKRGameState.points))

        if self.peerNetwork is WKRSoloNetwork {
            self.alertView.enqueue(text: "No stats in solo races", duration: 5)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceDurationConstants.resultsStandings) {
            self.peerNetwork.send(object: WKRCodable(enum: WKRGameState.voting))
        }
    }

    // MARK: - Voting

    func prepareVotingCountdown() {
        guard localPlayer.isHost else { fatalError("Local player not host") }
        DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceDurationConstants.votingPreCountdown) {
            self.startVotingCountdown()
        }
    }

    private func startVotingCountdown() {
        guard localPlayer.isHost else { fatalError("Local player not host") }

        var timeLeft = WKRRaceDurationConstants.votingState
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            timeLeft -= 1

            let voteTime = WKRCodable(int: WKRInt(type: .votingTime, value: timeLeft))
            self?.peerNetwork.send(object: voteTime)

            if timeLeft <= 0 {
                self?.prepareRaceConfig()
                timer.invalidate()
            }
        }
    }

    private func prepareRaceConfig() {
        guard localPlayer.isHost, let raceConfig = game.createRaceConfig() else {
            errorOccurred(.configCreationFailed)
            return
        }

        peerNetwork.send(object: WKRCodable(raceConfig))
        var timeLeft = WKRRaceDurationConstants.votingPreRace
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            timeLeft -= 1

            let voteTime = WKRCodable(int: WKRInt(type: .votingPreRaceTime, value: timeLeft))
            self?.peerNetwork.send(object: voteTime)

            if timeLeft <= 0 {
                let state = WKRGameState.race
                self?.peerNetwork.send(object: WKRCodable(enum: state))
                timer.invalidate()
            }
        }
    }

    internal func fetchPreRaceConfig() {
        guard localPlayer.isHost else { fatalError("Local player not host") }

        WKRPreRaceConfig.new { preRaceConfig in
            if let config = preRaceConfig {
                self.game.preRaceConfig = config
                self.sendPreRaceConfig()
                self.prepareVotingCountdown()
            } else {
                self.errorOccurred(.configCreationFailed)
            }
        }
    }

    internal func sendPreRaceConfig() {
        guard localPlayer.isHost else { fatalError("Local player not host") }

        // Make sure game hasn't already started
        guard game.activeRace == nil else {
            return
        }

        guard let unwrappedObject = game.preRaceConfig else {
            errorOccurred(.configCreationFailed)
            return
        }

        peerNetwork.send(object: WKRCodable(unwrappedObject))
    }
}
