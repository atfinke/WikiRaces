//
//  WKRManager+Host.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
extension WKRManager {

    /*// MARK: - Host Actions

     public func hostActionStartSession() {
     hostAction(sendMessage: .hostStartedSession)
     }

     //public func hostAction(transferHost: WKRPlayer) {}

     func hostActionShowVotingView() {}
     func hostAction(updatedVotingInfo: [WKRPage: Int]) {}

     func hostAction(updateVotingCountdown time: Int) {}
     func hostAction(updateHistoryCountdown time: Int) {}

     func hostAction(startingPageSelected: WKRPage) {}
     func hostAction(endingPageSelected: WKRPage) {}

     func hostActionSendHint(hint: String) {

     }

     func hostActionStartRace() {
     hostAction(sendMessage: .hostStartedRace)
     }
     func hostActionEndRace() {
     hostAction(sendMessage: .hostEndedRace)
     }
     func hostActionEndHistoryCountdown() {
     //hostAction(sendMessage: .hostEndedHistoryCountdown)
     }

     func hostAction(sendMessage message: WKRMessage) {
     send(message: message)
     // recieve local
     }*/

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
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            _debugLog(timeLeft)
            timeLeft -= 1

            let voteTime = WKRCodable(int: WKRInt(type: .resultsTime, value: timeLeft))
            self.peerNetwork.send(object: voteTime)

            if timeLeft <= 0 {
                timer.invalidate()

                self.peerNetwork.send(object: WKRCodable(enum: WKRGameState.points))
                DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceConstants.resultsPostHoldDuration, execute: {
                    self.peerNetwork.send(object: WKRCodable(enum: WKRGameState.voting))
                })
            }
        }
    }

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

        DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceConstants.votingPostHoldDuration) {
            let state = WKRGameState.race
            self.peerNetwork.send(object: WKRCodable(enum: state))
        }
    }
}
