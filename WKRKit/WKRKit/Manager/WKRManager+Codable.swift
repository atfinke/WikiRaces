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
            votingUpdate(.voteInfo(preRaceConfig.voteInfo))

            if webView?.url != preRaceConfig.startingPage.url {
                webView?.load(URLRequest(url: preRaceConfig.startingPage.url))
            }

            WKRSeenFinalArticlesStore.addLocalPlayerSeenFinalPages(preRaceConfig.voteInfo.pages)
        } else if let raceConfig = object.typeOf(WKRRaceConfig.self) {
            game.startRace(with: raceConfig)
            votingUpdate(.finalPage(raceConfig.endingPage))
        } else if let playerObject = object.typeOf(WKRPlayer.self) {
            if !game.players.contains(playerObject) && playerObject != localPlayer {
                peerNetwork.send(object: WKRCodable(localPlayer))
            }
            game.playerUpdated(playerObject)

            // if: other player just got to the same page
            // else if: local player just got to a new page
            var samePagePlayers = [WKRPlayerProfile]()
            if playerObject != localPlayer && game.shouldShowSamePageMessage(for: playerObject) {
                samePagePlayers.append(playerObject.profile)
            } else if playerObject == localPlayer {
                for player in game.players where game.shouldShowSamePageMessage(for: player) {
                    samePagePlayers.append(player.profile)
                }
            }

            var samePageMessage: String?
            if samePagePlayers.count == 1 {
                samePageMessage = "\(samePagePlayers[0].name) is on same page"
            } else if samePagePlayers.count > 1 {
                samePageMessage = "\(samePagePlayers.count) players are on same page"
            }
            if let message = samePageMessage {
                enqueue(message: message,
                        duration: 2.0,
                        isRaceSpecific: true,
                        playHaptic: false)
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
            var playHaptic = false
            if message == .quit {
                isRaceSpecific = false
            } else if message == .foundPage {
                playHaptic = true
            }

            // Don't show "on USA" message if expected to show "is on same page" message
            let lastPageTitle = localPlayer.raceHistory?.entries.last?.page.title ?? ""
            if message == .onUSA && lastPageTitle == "United States" {
                return
            }

            enqueue(message: message.text(for: player),
                    duration: 3.0,
                    isRaceSpecific: isRaceSpecific,
                    playHaptic: playHaptic)
        } else if let error = object.typeOfEnum(WKRFatalError.self), !isFailing {
            isFailing = true
            localPlayer.state = .quit
            peerNetwork.send(object: WKRCodable(localPlayer))
            peerNetwork.disconnect()
            gameUpdate(.error(error))
        }
    }

    internal func receivedInt(_ object: WKRCodable, from player: WKRPlayerProfile) {
        guard let int = object.typeOf(WKRInt.self) else { fatalError("Object not a WKRInt type") }
        switch int.type {
        case .votingTime, .votingPreRaceTime:
            votingUpdate(.remainingTime(int.value))
        case .resultsTime:
            resultsUpdate(.remainingTime(int.value))
        case .bonusPoints:
            let string = int.value == 1 ? "Point" : "Points"
            let message = "Race Bonus Now \(int.value) " + string
            enqueue(message: message,
                    duration: 2.0,
                    isRaceSpecific: true,
                    playHaptic: false)
        case .showReady:
            resultsUpdate(.isReadyUpEnabled(int.value == 1))
        }
    }

    // MARK: - Game Updates

    private func receivedFinalResults(_ resultsInfo: WKRResultsInfo) {
        alertView.clearRaceSpecificMessages()
        game.finishedRace()

        if gameState != .hostResults {
            transitionGameState(to: .hostResults)
        }

        hostResultsInfo = resultsInfo
        resultsUpdate(.hostResultsInfo(resultsInfo))

        if localPlayer.state == .racing {
            localPlayer.state = .forcedEnd
        }
        if localPlayer.shouldGetPoints {
            localPlayer.shouldGetPoints = false

            let points = resultsInfo.raceRewardPoints(for: localPlayer)
            var place: Int?
            for playerIndex in 0..<resultsInfo.playerCount {
                let player = resultsInfo.raceRankingsPlayer(at: playerIndex)
                if player == localPlayer && player.state == .foundPage {
                    place = playerIndex + 1
                }
            }
            let webViewPointsScrolled = webView?.pointsScrolled ?? 0
            gameUpdate(.playerStatsForLastRace(points: points,
                                               place: place,
                                               webViewPointsScrolled: webViewPointsScrolled))
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
                localErrorOccurred(.configCreationFailed)
                return
            }
            webView?.resetPixelCount()
            localPlayer.startedNewRace(on: raceConfig.startingPage)
        case .hostResults:
            localPlayer.raceHistory = nil
        default:
            break
        }

        peerNetwork.send(object: WKRCodable(localPlayer))
        gameUpdate(.state(state))
    }

}
