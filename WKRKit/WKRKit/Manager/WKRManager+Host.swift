//
//  WKRGameManager+Host.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

extension WKRGameManager {

    // MARK: - Results

    func prepareResultsCountdown() {
        guard localPlayer.isHost else { fatalError("Local player not host") }

        var delay = WKRRaceDurationConstants.resultsPreCountdown
        if peerNetwork is WKRSoloNetwork {
            delay = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.startResultsCountdown()
        }
    }

    private func startResultsCountdown() {
        guard localPlayer.isHost else { fatalError("Local player not host") }

        var timeLeft = settings.timing.resultsTime
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }

            if self.gameState != .hostResults {
                timer.invalidate()
                return
            }

            timeLeft -= 1

            let resultsTime = WKRCodable(int: WKRInt(type: .resultsTime, value: timeLeft))
            self.peerNetwork.send(object: resultsTime)

            let showReadyTime = self.settings.timing.resultsTime - WKRRaceDurationConstants.resultsShowReadyAfter

            if timeLeft <= 0 {
                self.finishResultsCountdown()
                timer.invalidate()
            } else if timeLeft == showReadyTime {
                let showReady = WKRCodable(int: WKRInt(type: .showReady, value: 1))
                self.peerNetwork.send(object: showReady)
            } else if timeLeft == WKRRaceDurationConstants.resultsDisableReadyBefore {
                let showReady = WKRCodable(int: WKRInt(type: .showReady, value: 0))
                self.peerNetwork.send(object: showReady)
            }
        }
    }

    internal func finishResultsCountdown() {
        guard localPlayer.isHost && gameState != .points else { return }

        self.game.players = []

        if peerNetwork is WKRSoloNetwork {
            // skip points and go straight to voting if solo
            peerNetwork.send(object: WKRCodable(enum: WKRGameState.voting))
            return
        }

        self.peerNetwork.send(object: WKRCodable(enum: WKRGameState.points))
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

        var timeLeft = settings.timing.votingTime
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
        guard localPlayer.isHost, let raceConfigCreation = game.createRaceConfig(), let config = raceConfigCreation.config else {
            localErrorOccurred(.configCreationFailed)
            return
        }

        if let logEvent = raceConfigCreation.logEvent {
            gameUpdate(.log(logEvent))
        }

        peerNetwork.send(object: WKRCodable(config))
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

        WKRPreRaceConfig.new(settings: settings) { preRaceConfig, logEvents in
            if let config = preRaceConfig {
                self.game.preRaceConfig = config
                self.sendPreRaceConfig()
                self.prepareVotingCountdown()
            } else {
                self.localErrorOccurred(.configCreationFailed)
            }
            logEvents.forEach { self.gameUpdate(.log($0)) }
        }
    }

    internal func sendPreRaceConfig() {
        guard localPlayer.isHost else { fatalError("Local player not host") }

        // Make sure game hasn't already started
        guard game.activeRace == nil else {
            return
        }

        guard let unwrappedObject = game.preRaceConfig else {
            localErrorOccurred(.configCreationFailed)
            return
        }

        peerNetwork.send(object: WKRCodable(unwrappedObject))
    }
}
