//
//  WKRManager+Codable.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
extension WKRManager {

    // MARK: - Object Handling

    internal func receivedRaw(_ object: WKRCodable, from player: WKRPlayerProfile) {
        if let preRaceConfig = object.typeOf(WKRPreRaceConfig.self) {
            _debugLog(preRaceConfig)
            game.preRaceConfig = preRaceConfig

            if webView.url != preRaceConfig.startingPage.url {
                webView?.load(URLRequest(url: preRaceConfig.startingPage.url))
            }

            voteInfoUpdate?(preRaceConfig.voteInfo)
            debugEntry.append(WKRDebugEntry(object: preRaceConfig, sender: player))
        } else if let raceConfig = object.typeOf(WKRRaceConfig.self) {
            _debugLog(raceConfig)
            game.startRace(with: raceConfig)
            voteFinalPageUpdate?(raceConfig.endingPage)
            debugEntry.append(WKRDebugEntry(object: raceConfig, sender: player))
        } else if let playerObject = object.typeOf(WKRPlayer.self) {
            _debugLog(playerObject)
            game.playerUpdated(playerObject)
            playersUpdate(allPlayers)

            // Player joined mid-session
            if playerObject.state == .connecting && localPlayer.state != .connecting {
                // Send self
                peerNetwork.send(object: WKRCodable(localPlayer))
                if localPlayer.isHost {
                    // Send latest results
                    // TODO: Send ready states
                    if let results = hostResultsInfo {
                        peerNetwork.send(object: WKRCodable(results))
                    }
                }
            }
            debugEntry.append(WKRDebugEntry(object: playerObject, sender: player))
        } else if let resultsInfo = object.typeOf(WKRResultsInfo.self), hostResultsInfo == nil {
            _debugLog(resultsInfo)
            game.finishedRace()
            hostResultsInfo = resultsInfo
            resultsInfoHostUpdate?(resultsInfo)

            if localPlayer.state.isRacing {
                localPlayer.state = .forcedEnd
                peerNetwork.send(object: WKRCodable(localPlayer))
            }

            debugEntry.append(WKRDebugEntry(object: resultsInfo, sender: player))
        } else if let pageVote = object.typeOf(WKRPage.self) {
            if localPlayer.isHost {
                game.player(player, votedFor: pageVote)
                sendPreRaceConfig()
            }
            debugEntry.append(WKRDebugEntry(object: pageVote, sender: player))
        } else {
            _debugLog("No Case")
        }
    }

    internal func receivedEnum(_ object: WKRCodable, from player: WKRPlayerProfile) {
        if let gameState = object.typeOfEnum(WKRGameState.self) {
            _debugLog(gameState)
            transitionGameState(to: gameState)
            debugEntry.append(WKRDebugEntry(object: gameState, sender: player))
        } else if let message = object.typeOfEnum(WKRPlayerMessage.self) {
            _debugLog(message)
            if player != localPlayer.profile {
                enqueue(message: message.text(for: player), duration: 2.0)
            }
            debugEntry.append(WKRDebugEntry(object: message, sender: player))
        } else if let message = object.typeOfEnum(WKRPlayerState.self) {
            _debugLog(message)
            game.player(player, stateUpdated: message)
            playersUpdate(game.players)
            debugEntry.append(WKRDebugEntry(object: message, sender: player))
        } else {
            fatalError()
        }
    }

    internal func receivedInt(_ object: WKRCodable, from player: WKRPlayerProfile) {
        guard let int = object.typeOf(WKRInt.self) else { fatalError() }
        switch int.type {
        case .votingTime, .votingPreRaceTime:
            voteTimeUpdate?(int.value)
            debugEntry.append(WKRDebugEntry(object: int, sender: player))
        case .resultsTime:
            resultsTimeUpdate?(int.value)
            debugEntry.append(WKRDebugEntry(object: int, sender: player))
        case .bonusPoints:
            let string = int.value == 1 ? "Point" : "Points"
            let message = "Match Bonus Now \(int.value) " + string
            enqueue(message: message)
        case .showReady:
            resultsShowReady?(int.value == 1)
        }
    }

    // MARK: - Game Updates

    internal func transitionGameState(to state: WKRGameState) {
        _debugLog(state)
        game.state = state

        if state == .voting {
            localPlayer.startedVoting()
            peerNetwork.send(object: WKRCodable(localPlayer))

            if localPlayer.isHost {
                fetchPreRaceConfig()
            }
        } else if state == .race, let raceConfig = game.raceConfig {
            let state = WKRPlayerState.racing
            peerNetwork.send(object: WKRCodable(enum: state))

            localPlayer.startedNewRace(on: raceConfig.startingPage)
            peerNetwork.send(object: WKRCodable(localPlayer))
        } else if state == .hostResults {
            localPlayer.raceHistory = nil
            peerNetwork.send(object: WKRCodable(localPlayer))
        }

        stateUpdate(state)
    }

    // MARK: - Host Functions

    private func fetchPreRaceConfig() {
        _debugLog()
        assert(localPlayer.isHost)

        WKRPreRaceConfig.new { preRaceConfig in
            _debugLog(preRaceConfig)
            if let config = preRaceConfig {
                self.game.preRaceConfig = config
                self.sendPreRaceConfig()
                self.prepareVotingCountdown()
            } else {
                fatalError("Need to add connection failed error")
            }
        }
    }

    private func sendPreRaceConfig() {
        _debugLog()
        assert(localPlayer.isHost)

        // Make sure game hasn't already started
        guard game.activeRace == nil else {
            return
        }

        guard let unwrappedObject = game.preRaceConfig else {
            fatalError()
        }

        _debugLog(unwrappedObject)
        DispatchQueue.main.async {
            self.peerNetwork.send(object: WKRCodable(unwrappedObject))
        }
    }

}
