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
        game.allPlayersReadyForNextRound = {
            if self.localPlayer.isHost && self.gameState == .hostResults && self.resultsTimer != nil {
                self.finishResultsCountdown()
            }
        }
        game.bonusPointsUpdated = { points in
            let bonusPoints = WKRCodable(int: WKRInt(type: .bonusPoints, value: points))
            self.peerNetwork.send(object: bonusPoints)
        }
        game.finalResultsCreated = { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceConstants.racePostHoldDuration) {
                let state = WKRGameState.hostResults
                self.peerNetwork.send(object: WKRCodable(enum: state))
                self.peerNetwork.send(object: WKRCodable(result))
                self.prepareResultsCountdown()
            }
        }
    }

    // MARK: - Results

    func prepareResultsCountdown() {
        _debugLog()
        assert(localPlayer.isHost)

        DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceConstants.resultsPreHoldDuration) {
            self.startResultsCountdown()
        }
    }

    private func startResultsCountdown() {
        _debugLog()
        assert(localPlayer.isHost)

        var timeLeft = WKRRaceConstants.resultsDuration
        resultsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            _debugLog(timeLeft)
            timeLeft -= 1

            let resultsTime = WKRCodable(int: WKRInt(type: .resultsTime, value: timeLeft))
            self.peerNetwork.send(object: resultsTime)

            if timeLeft <= 0 {
                self.finishResultsCountdown()
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
        resultsTimer?.invalidate()

        self.peerNetwork.send(object: WKRCodable(enum: WKRGameState.points))
        DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceConstants.resultsPostHoldDuration) {
            self.peerNetwork.send(object: WKRCodable(enum: WKRGameState.voting))
        }
    }

    // MARK: - Voting

    func prepareVotingCountdown() {
        _debugLog()
        assert(localPlayer.isHost)

        DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceConstants.votingPreHoldDuration) {
            self.startVotingCountdown()
        }
    }

    private func startVotingCountdown() {
        _debugLog()
        assert(localPlayer.isHost)

        var timeLeft = WKRRaceConstants.votingDuration
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            _debugLog(timeLeft)
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
        _debugLog()
        assert(localPlayer.isHost)

        guard let raceConfig = game.createRaceConfig() else {
            _debugLog("Failed to create race")
            return
        }

        peerNetwork.send(object: WKRCodable(raceConfig))
        var timeLeft = WKRRaceConstants.votingPreRaceDuration
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            _debugLog(timeLeft)
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
}
