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
            game.preRaceConfig = preRaceConfig
            voteInfoUpdate?(preRaceConfig.voteInfo)

            if webView.url != preRaceConfig.startingPage.url {
                webView?.load(URLRequest(url: preRaceConfig.startingPage.url))
            }
        } else if let raceConfig = object.typeOf(WKRRaceConfig.self) {
            game.startRace(with: raceConfig)
            voteFinalPageUpdate?(raceConfig.endingPage)
        } else if let playerObject = object.typeOf(WKRPlayer.self) {
            game.playerUpdated(playerObject)
            playersUpdate(game.players)

            // Player joined mid-session
            if playerObject.state == .connecting {
                peerNetwork.send(object: WKRCodable(localPlayer))
                if let results = hostResultsInfo, localPlayer.isHost && gameState == .hostResults {
                    peerNetwork.send(object: WKRCodable(results))
                }
            }
        } else if let resultsInfo = object.typeOf(WKRResultsInfo.self), hostResultsInfo == nil {
            game.finishedRace()

            if gameState != .hostResults {
                transitionGameState(to: .hostResults)
            }

            hostResultsInfo = resultsInfo
            resultsInfoHostUpdate?(resultsInfo)

            if localPlayer.state.isRacing {
                localPlayer.state = .forcedEnd
            }

            localPlayer.raceHistory = nil
            peerNetwork.send(object: WKRCodable(localPlayer))
        } else if let pageVote = object.typeOf(WKRPage.self), localPlayer.isHost {
            game.player(player, votedFor: pageVote)
            sendPreRaceConfig()
        }
    }

    internal func receivedEnum(_ object: WKRCodable, from player: WKRPlayerProfile) {
        if let gameState = object.typeOfEnum(WKRGameState.self) {
            transitionGameState(to: gameState)
        } else if let message = object.typeOfEnum(WKRPlayerMessage.self) {
            if player != localPlayer.profile {
                enqueue(message: message.text(for: player), duration: 2.0)
            }
        } else {
            fatalError()
        }
    }

    internal func receivedInt(_ object: WKRCodable, from player: WKRPlayerProfile) {
        guard let int = object.typeOf(WKRInt.self) else { fatalError() }
        switch int.type {
        case .votingTime, .votingPreRaceTime:
            voteTimeUpdate?(int.value)
        case .resultsTime:
            resultsTimeUpdate?(int.value)
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
        game.state = state

        switch state {
        case .voting:
            hostResultsInfo = nil
            localPlayer.state = .voting
            localPlayer.raceHistory = nil
            if localPlayer.isHost {
                fetchPreRaceConfig()
            }
        case .race:
            guard let raceConfig = game.raceConfig else {
                fatalError()
            }
            localPlayer.startedNewRace(on: raceConfig.startingPage)
        case .hostResults:
            localPlayer.raceHistory = nil
        default:
            break
        }

        peerNetwork.send(object: WKRCodable(localPlayer))
        stateUpdate(state)
    }

}
