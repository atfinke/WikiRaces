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

    public var votingInfo: WKRVoteInfo? {
        return game.preRaceConfig?.voteInfo
    }

    public var gameState: WKRGameState {
        return game.state
    }

    public var allPlayers: [WKRPlayer] {
        return game.players
    }

    public var racePlayers: [WKRPlayer] {
        return game.activeRace?.players ?? []
    }

    public var hostResultsInfo: WKRResultsInfo?

    // MARK: - Properties

    internal let game: WKRGame
    internal let localPlayer: WKRPlayer
    internal let peerNetwork: WKRPeerNetwork

    internal var resultsTimer: Timer?
    internal var pageNavigation: WKRPageNavigation!

    // MARK: - Callbacks

    internal let stateUpdate: ((WKRGameState) -> Void)
    internal let playersUpdate: (([WKRPlayer]) -> Void)

    internal var resultsTimeUpdate: ((Int) -> Void)?
    internal var resultsInfoHostUpdate: ((WKRResultsInfo) -> Void)?

    internal var voteTimeUpdate: ((Int) -> Void)?
    internal var voteInfoUpdate: ((WKRVoteInfo) -> Void)?
    internal var voteFinalPageUpdate: ((WKRPage) -> Void)?

    // MARK: - User Interface

    internal var webView: WKRUIWebView!
    internal var alertView: WKRUIAlertView!

    // MARK: - Debug

    internal struct WKRDebugEntry {
        let date = Date()
        let object: Any
        let sender: WKRPlayerProfile
    }

    internal var debugEntry = [WKRDebugEntry]()

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

    // MARK: View Controller Callbacks

    public func voting(timeUpdate: @escaping ((Int) -> Void),
                       infoUpdate: @escaping ((WKRVoteInfo) -> Void),
                       finalPageUpdate: @escaping ((WKRPage) -> Void)) {
        voteTimeUpdate = timeUpdate
        voteInfoUpdate = infoUpdate
        voteFinalPageUpdate = finalPageUpdate
    }

    public func results(timeUpdate: @escaping ((Int) -> Void),
                        infoUpdate: @escaping ((WKRResultsInfo) -> Void),
                        hostInfoUpdate: @escaping ((WKRResultsInfo) -> Void),
                        readyStatesUpdate: @escaping ((WKRReadyStates) -> Void)) {

        resultsTimeUpdate = timeUpdate
        resultsInfoHostUpdate = hostInfoUpdate

        game.readyStatesUpdated = readyStatesUpdate
        game.currentResultsUpdated = { results in
            if self.gameState == .results {
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

    public func presentNetworkInterface(on viewController: UIViewController) {
        peerNetwork.presentNetworkInterface(on: viewController)
    }

    public func enqueue(message: String, duration: Double = 5.0) {
        alertView.enqueue(text: message, duration: duration)
    }

    // MARK: - Actions

    public func player(_ action: WKRPlayerAction) {
        _debugLog(action)
        switch action {
        case .ready:
            localPlayer.isReadyForNextRound = true
            peerNetwork.send(object: WKRCodable(localPlayer))
        case .startedGame:
            let state = WKRGameState.voting
            peerNetwork.send(object: WKRCodable(enum: state))
        case .voted(let page):
            peerNetwork.send(object: WKRCodable(page))
        case .neededHelp:
            peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.neededHelp))
        case .forfeited:
            peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.forfeited))
            localPlayer.state = .forfeited
            peerNetwork.send(object: WKRCodable(localPlayer))
            transitionGameState(to: .results)
        case .quit:
            peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.quit))
            localPlayer.state = .quit
            peerNetwork.send(object: WKRCodable(localPlayer))
            peerNetwork.disconnect()
        default: fatalError("\(action)")
        }
    }
}

extension Array where Element == WKRManager.WKRDebugEntry {
    func printFormatted() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        var string = ""
        for entry in self {
            string += "=========\n\nDate: \(formatter.string(from: entry.date))\nFrom: \(entry.sender.name)\n"
            string += "Object: \(entry.object)\n\n"
        }
        print(string)
    }
}
