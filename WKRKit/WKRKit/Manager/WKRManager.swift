//
//  WKRGameManager.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WKRUIKit

final public class WKRGameManager {

    // MARK: Types

    public enum GameUpdate {
        case state(WKRGameState)
        case error(WKRFatalError)
        case log(WKRLogEvent)

        case playerRaceLinkCountForCurrentRace(Int)
        case playerStatsForLastRace(points: Int, place: Int?, webViewPixelsScrolled: Int)
    }

    public enum VotingUpdate {
        case remainingTime(Int)
        case voteInfo(WKRVoteInfo)
        case finalPage(WKRPage)
    }

    public enum ResultsUpdate {
        case isReadyUpEnabled(Bool)
        case remainingTime(Int)
        case resultsInfo(WKRResultsInfo)
        case hostResultsInfo(WKRResultsInfo)
        case readyStates(WKRReadyStates)
    }

    // MARK: - Public Getters

    public var finalPageURL: URL? {
        return game.raceConfig?.endingPage.url
    }

    public var voteInfo: WKRVoteInfo? {
        return game.preRaceConfig?.voteInfo
    }

    public var gameState: WKRGameState {
        return game.state
    }

    public var hostResultsInfo: WKRResultsInfo?

    // MARK: - Properties

    internal var isFailing = false

    internal let game: WKRGame
    public   let localPlayer: WKRPlayer
    internal let peerNetwork: WKRPeerNetwork
    internal var pageNavigation: WKRPageNavigation?

    internal let settings: WKRGameSettings

    // MARK: - Closures

    internal let gameUpdate: ((GameUpdate) -> Void)
    internal let votingUpdate: ((VotingUpdate) -> Void)
    internal let resultsUpdate: ((ResultsUpdate) -> Void)

    // MARK: - User Interface

    public weak var webView: WKRUIWebView? {
        didSet {
            createPageNavigation()
        }
    }
    public let alertView = WKRUIAlertView()

    // MARK: - Initialization

    public init(networkConfig: WKRPeerNetworkConfig,
                settings: WKRGameSettings,
                gameUpdate: @escaping ((GameUpdate) -> Void),
                votingUpdate: @escaping ((VotingUpdate) -> Void),
                resultsUpdate: @escaping ((ResultsUpdate) -> Void)) {
        self.settings = settings
        self.gameUpdate = gameUpdate
        self.votingUpdate = votingUpdate
        self.resultsUpdate = resultsUpdate

        let setup = networkConfig.create()
        localPlayer = setup.player
        localPlayer.isCreator = WKRPlayer.isLocalPlayerCreator
        peerNetwork = setup.network

        game = WKRGame(localPlayer: localPlayer, isSolo: peerNetwork is WKRSoloNetwork, settings: settings)
        game.listenerUpdate = { [weak self] update in
            guard let self = self else { return }
            switch update {
            case .bonusPoints(let points):
                guard self.localPlayer.isHost else { return }
                let bonusPoints = WKRCodable(int: WKRInt(type: .bonusPoints, value: points))
                self.peerNetwork.send(object: bonusPoints)
            case .playersReadyForNextRound:
                guard self.localPlayer.isHost, self.gameState == .hostResults else { return }
                //swiftlint:disable:next line_length
                DispatchQueue.main.asyncAfter(deadline: .now() + WKRRaceDurationConstants.resultsAllReadyDelay, execute: {
                    self.finishResultsCountdown()
                })
            case .readyStates(let states):
                resultsUpdate(.readyStates(states))
            case .hostResults(let results):
                guard self.localPlayer.isHost else { return }
                DispatchQueue.main.async {
                    let state = WKRGameState.hostResults
                    self.peerNetwork.send(object: WKRCodable(enum: state))
                    self.peerNetwork.send(object: WKRCodable(results))
                    self.prepareResultsCountdown()
                }
            case .localResults(let results):
                guard self.gameState == .results || self.gameState == .race else { return }
                resultsUpdate(.resultsInfo(results))
            }
        }

        configure(network: peerNetwork)
        peerNetwork.send(object: WKRCodable(self.localPlayer))
    }

    // MARK: - User Interface

    public func hostNetworkInterface() -> UIViewController? {
        return peerNetwork.hostNetworkInterface()
    }

    public func enqueue(message: String, duration: Double, isRaceSpecific: Bool, playHaptic: Bool) {
        alertView.enqueue(text: message,
                          duration: duration,
                          isRaceSpecific: isRaceSpecific,
                          playHaptic: playHaptic)
    }

    // MARK: - Actions

    internal func localErrorOccurred(_ error: WKRFatalError) {
        let codable = WKRCodable(enum: error)
        if error == .configCreationFailed && localPlayer.isHost {
            peerNetwork.send(object: codable)
        } else {
            receivedEnum(codable, from: localPlayer.profile)
        }
    }

    public func player(_ action: WKRPlayerAction) {
        switch action {
        case .ready:
            localPlayer.state = .readyForNextRound
            peerNetwork.send(object: WKRCodable(localPlayer))
        case .startedGame:
            let state = WKRGameState.voting
            peerNetwork.send(object: WKRCodable(enum: state))
        case .voted(let page):
            peerNetwork.send(object: WKRCodable(page))
        case .neededHelp:
            localPlayer.neededHelp()
            peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.neededHelp))
        case .forfeited:
            localPlayer.state = .forfeited
            peerNetwork.send(object: WKRCodable(localPlayer))
            peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.forfeited))
            transitionGameState(to: .results)
        case .quit:
            peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.quit))
            peerNetwork.disconnect()
            alertView.forceDismiss()
        default: fatalError("\(action)")
        }
    }
}
