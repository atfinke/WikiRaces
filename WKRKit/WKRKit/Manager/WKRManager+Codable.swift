//
//  WKRGameManager+Codable.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

extension WKRGameManager {

    // MARK: - Object Handling

    internal func receivedRaw(_ object: WKRCodable, from player: WKRPlayerProfile) {
        if let preRaceConfig = object.typeOf(WKRPreRaceConfig.self) {
            game.preRaceConfig = preRaceConfig
            voteInfoUpdate?(preRaceConfig.voteInfo)

            if webView?.url != preRaceConfig.startingPage.url {
                webView?.load(URLRequest(url: preRaceConfig.startingPage.url))
            }

            WKRSeenFinalArticlesStore.addLocalPlayerSeenFinalPages(preRaceConfig.voteInfo.pages)
        } else if let raceConfig = object.typeOf(WKRRaceConfig.self) {
            game.startRace(with: raceConfig)
            voteFinalPageUpdate?(raceConfig.endingPage)
        } else if let playerObject = object.typeOf(WKRPlayer.self) {
            if !game.players.contains(playerObject) && playerObject != localPlayer {
                peerNetwork.send(object: WKRCodable(localPlayer))
            }
            game.playerUpdated(playerObject)

            if playerObject != localPlayer && game.shouldShowSamePageMessage(for: playerObject) {
                enqueue(message: "\(player.name) is on same page", isRaceSpecific: true)
            } else if playerObject == localPlayer {
                for player in game.players where game.shouldShowSamePageMessage(for: player) {
                    enqueue(message: "\(player.name) is on same page", isRaceSpecific: true)
                }
            }

            // Player joined mid-session
            if playerObject.state == .connecting
                && localPlayer.state != .connecting
                && localPlayer.isHost
                && gameState == .hostResults,
                let results = hostResultsInfo {
                peerNetwork.send(object: WKRCodable(results))
            }
        } else if let resultsInfo = object.typeOf(WKRResultsInfo.self), hostResultsInfo == nil {
            receivedFinalResults(resultsInfo)
        } else if let pageVote = object.typeOf(WKRPage.self), localPlayer.isHost {
            game.player(player, votedFor: pageVote)
            sendPreRaceConfig()
        }
    }

    internal func receivedEnum(_ object: WKRCodable, from player: WKRPlayerProfile) {
        if let gameState = object.typeOfEnum(WKRGameState.self) {
            transitionGameState(to: gameState)
        } else if let message = object.typeOfEnum(WKRPlayerMessage.self), player != localPlayer.profile {
            var isRaceSpecific = true
            if message == .quit {
                isRaceSpecific = false
            }
            enqueue(message: message.text(for: player), duration: 5.0, isRaceSpecific: isRaceSpecific)
        } else if let error = object.typeOfEnum(WKRFatalError.self), !isFailing {
            isFailing = true
            localPlayer.state = .quit
            peerNetwork.send(object: WKRCodable(localPlayer))
            peerNetwork.disconnect()
            stateUpdate(gameState, error)
        }
    }

    internal func receivedInt(_ object: WKRCodable, from player: WKRPlayerProfile) {
        guard let int = object.typeOf(WKRInt.self) else { fatalError("Object not a WKRInt type") }
        switch int.type {
        case .votingTime, .votingPreRaceTime:
            voteTimeUpdate?(int.value)
        case .resultsTime:
            resultsTimeUpdate?(int.value)
        case .bonusPoints:
            let string = int.value == 1 ? "Point" : "Points"
            let message = "Match Bonus Now \(int.value) " + string
            enqueue(message: message, isRaceSpecific: true)
        case .showReady:
            resultsShowReady?(int.value == 1)
        }
    }

    // MARK: - Game Updates

    private func receivedFinalResults(_ resultsInfo: WKRResultsInfo) {
        alertView.clearRaceSpecificMessages()
        game.finishedRace()

        if gameState != .hostResults {
            transitionGameState(to: .hostResults)

            WKRConnectionTester.start(timeout: 15.0, completionHandler: { success in
                if !success {
                    self.errorOccurred(.internetSpeed)
                }
            })
        }

        hostResultsInfo = resultsInfo
        resultsInfoHostUpdate?(resultsInfo)

        if localPlayer.state == .racing {
            localPlayer.state = .forcedEnd
        }
        if localPlayer.shouldGetPoints {
            localPlayer.shouldGetPoints = false
            pointsUpdate(resultsInfo.raceRewardPoints(for: localPlayer))
        }

        peerNetwork.send(object: WKRCodable(localPlayer))
    }

    internal func transitionGameState(to state: WKRGameState) {
        game.state = state

        switch state {
        case .voting:
            hostResultsInfo = nil
            localPlayer.state = .voting
            localPlayer.raceHistory = nil
            localPlayer.shouldGetPoints = true
            if localPlayer.isHost {
                fetchPreRaceConfig()
            }
        case .race:
            guard let raceConfig = game.raceConfig else {
                errorOccurred(.configCreationFailed)
                return
            }
            localPlayer.startedNewRace(on: raceConfig.startingPage)
        case .hostResults:
            localPlayer.raceHistory = nil
        default:
            break
        }

        peerNetwork.send(object: WKRCodable(localPlayer))
        stateUpdate(state, nil)
    }

}
