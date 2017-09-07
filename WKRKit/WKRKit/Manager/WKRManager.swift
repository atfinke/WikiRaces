//
//  WKRManager.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WKRUIKit

public enum WKRPlayerAction {
    case startedGame
    case neededHelp
    case voted(WKRPage)
    case state(WKRPlayerState)
    case forfeited
    case quit
    case ready
}

public class WKRManager {

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

    public var racePlayers: [WKRPlayer] {
        return game.activeRace?.players ?? []
    }

    public var hostResultsInfo: WKRResultsInfo?

    // MARK: - Properties

    internal let game: WKRGame
    internal let localPlayer: WKRPlayer
    internal let peerNetwork: WKRPeerNetwork
    internal var pageNavigation: WKRPageNavigation!

    // MARK: - Closures

    internal let stateUpdate: ((WKRGameState) -> Void)
    internal let playersUpdate: (([WKRPlayer]) -> Void)

    internal var resultsShowReady: ((Bool) -> Void)?
    internal var resultsTimeUpdate: ((Int) -> Void)?
    internal var resultsInfoHostUpdate: ((WKRResultsInfo) -> Void)?

    internal var voteTimeUpdate: ((Int) -> Void)?
    internal var voteInfoUpdate: ((WKRVoteInfo) -> Void)?
    internal var voteFinalPageUpdate: ((WKRPage) -> Void)?

    // MARK: - User Interface

    internal weak var webView: WKRUIWebView!
    internal weak var alertView: WKRUIAlertView!

    // MARK: - Initialization

    internal init(player: WKRPlayer,
                  network: WKRPeerNetwork,
                  stateUpdate: @escaping ((WKRGameState) -> Void),
                  playersUpdate: @escaping (([WKRPlayer]) -> Void)) {

        self.stateUpdate = stateUpdate
        self.playersUpdate = playersUpdate

        localPlayer = player
        peerNetwork = network

        game = WKRGame(localPlayer: localPlayer)
        if player.isHost {
            configure(game: game)
        }

        configure(network: peerNetwork)

        peerNetwork.send(object: WKRCodable(self.localPlayer))
        playersUpdate(game.players)
    }

    // MARK: View Controller Closures

    public func voting(timeUpdate: @escaping ((Int) -> Void),
                       infoUpdate: @escaping ((WKRVoteInfo) -> Void),
                       finalPageUpdate: @escaping ((WKRPage) -> Void)) {
        voteTimeUpdate = timeUpdate
        voteInfoUpdate = infoUpdate
        voteFinalPageUpdate = finalPageUpdate
    }

    public func results(showReady: @escaping ((Bool) -> Void),
                        timeUpdate: @escaping ((Int) -> Void),
                        infoUpdate: @escaping ((WKRResultsInfo) -> Void),
                        hostInfoUpdate: @escaping ((WKRResultsInfo) -> Void),
                        readyStatesUpdate: @escaping ((WKRReadyStates) -> Void)) {

        resultsShowReady = showReady
        resultsTimeUpdate = timeUpdate
        resultsInfoHostUpdate = hostInfoUpdate

        game.readyStatesUpdated = readyStatesUpdate
        game.localResultsUpdated = { results in
            if self.gameState == .results || self.gameState == .race {
                infoUpdate(results)
            }
        }
    }

    // MARK: User Interface

    public func configure(webView: WKRUIWebView, alertView: WKRUIAlertView) {
        self.webView = webView
        self.alertView = alertView

        pageNavigation = newPageNavigation()
        webView.navigationDelegate = pageNavigation
    }

    public func hostNetworkInterface() -> UIViewController {
        return peerNetwork.hostNetworkInterface()
    }

    public func enqueue(message: String, duration: Double = 5.0) {
        alertView.enqueue(text: message, duration: duration)
    }

    // MARK: - Actions

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
            peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.neededHelp))
        case .forfeited:
            localPlayer.state = .forfeited
            peerNetwork.send(object: WKRCodable(localPlayer))
            peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.forfeited))
            transitionGameState(to: .results)
        case .quit:
            peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.quit))
            peerNetwork.disconnect()
        default: fatalError("\(action)")
        }
    }
}
