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
        guard localPlayer.isHost else { fatalError() }

        game.allPlayersReadyForNextRound = {
            if self.localPlayer.isHost && self.gameState == .hostResults {
                self.finishResultsCountdown()
            }
        }
        game.bonusPointsUpdated = { points in
            let bonusPoints = WKRCodable(int: WKRInt(type: .bonusPoints, value: points))
            self.peerNetwork.send(object: bonusPoints)
        }
        game.hostResultsCreated = { result in
            DispatchQueue.main.async {
                let state = WKRGameState.hostResults
                self.peerNetwork.send(object: WKRCodable(enum: state))
                self.peerNetwork.send(object: WKRCodable(result))
                self.prepareResultsCountdown()
            }
        }
    }

    // MARK: - Results

    func prepareResultsCountdown() {
        guard localPlayer.isHost else { fatalError() }

        DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceConstants.resultsPreHoldDuration) {
            self.startResultsCountdown()
        }
    }

    private func startResultsCountdown() {
        guard localPlayer.isHost else { fatalError() }

        var timeLeft = WKRRaceConstants.resultsDuration
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in

            if self.gameState == .points {
                timer.invalidate()
                return
            }

            timeLeft -= 1

            let resultsTime = WKRCodable(int: WKRInt(type: .resultsTime, value: timeLeft))
            self.peerNetwork.send(object: resultsTime)

            if timeLeft <= 0 {
                self.finishResultsCountdown()
                timer.invalidate()
            } else if timeLeft == WKRRaceConstants.resultsDuration - WKRRaceConstants.resultsHoldReadyDuration {
                let showReady = WKRCodable(int: WKRInt(type: .showReady, value: 1))
                self.peerNetwork.send(object: showReady)
            } else if timeLeft == WKRRaceConstants.resultsDisableReadyTime {
                let showReady = WKRCodable(int: WKRInt(type: .showReady, value: 0))
                self.peerNetwork.send(object: showReady)
            }
        }
    }

    internal func finishResultsCountdown() {
        guard localPlayer.isHost && gameState != .points else { fatalError() }

        self.game.players = []

        self.peerNetwork.send(object: WKRCodable(enum: WKRGameState.points))
        DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceConstants.resultsPostHoldDuration) {
            self.peerNetwork.send(object: WKRCodable(enum: WKRGameState.voting))
        }
    }

    // MARK: - Voting

    func prepareVotingCountdown() {
        guard localPlayer.isHost else { fatalError() }
        DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceConstants.votingPreHoldDuration) {
            self.startVotingCountdown()
        }
    }

    private func startVotingCountdown() {
        guard localPlayer.isHost else { fatalError() }

        var timeLeft = WKRRaceConstants.votingDuration
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            timeLeft -= 1

            let voteTime = WKRCodable(int: WKRInt(type: .votingTime, value: timeLeft))
            self.peerNetwork.send(object: voteTime)

            if timeLeft <= 0 {
                self.prepareRaceConfig()
                timer.invalidate()
            }
        }
    }

    private func prepareRaceConfig() {
        guard localPlayer.isHost, let raceConfig = game.createRaceConfig() else {
            fatalError("Failed to create race")
        }

        peerNetwork.send(object: WKRCodable(raceConfig))
        var timeLeft = WKRRaceConstants.votingPreRaceDuration
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            timeLeft -= 1

            let voteTime = WKRCodable(int: WKRInt(type: .votingPreRaceTime, value: timeLeft))
            self.peerNetwork.send(object: voteTime)

            if timeLeft <= 0 {
                let state = WKRGameState.race
                self.peerNetwork.send(object: WKRCodable(enum: state))
                timer.invalidate()
            }
        }
    }

    internal func fetchPreRaceConfig() {
        guard localPlayer.isHost else { fatalError() }

        WKRPreRaceConfig.new { preRaceConfig in
            if let config = preRaceConfig {
                self.game.preRaceConfig = config
                self.sendPreRaceConfig()
                self.prepareVotingCountdown()
            } else {
                fatalError("Need to add connection failed error")
            }
        }
    }

    internal func sendPreRaceConfig() {
        guard localPlayer.isHost else { fatalError() }

        // Make sure game hasn't already started
        guard game.activeRace == nil else {
            return
        }

        guard let unwrappedObject = game.preRaceConfig else {
            fatalError()
        }

        peerNetwork.send(object: WKRCodable(unwrappedObject))
    }
}
