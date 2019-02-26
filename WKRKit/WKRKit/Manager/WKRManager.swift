//
//  WKRGameManager.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WKRUIKit

public class WKRGameManager {

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
    internal var pageNavigation: WKRPageNavigation!

    // MARK: - Closures

    internal let stateUpdate: ((WKRGameState, WKRFatalError?) -> Void)
    internal let pointsUpdate: ((Int) -> Void)
    internal let linkCountUpdate: ((Int) -> Void)
    internal let logEvent: ((String, [String: Any]?) -> Void)

    internal var resultsShowReady: ((Bool) -> Void)?
    internal var resultsTimeUpdate: ((Int) -> Void)?
    internal var resultsInfoHostUpdate: ((WKRResultsInfo) -> Void)?

    internal var voteTimeUpdate: ((Int) -> Void)?
    internal var voteInfoUpdate: ((WKRVoteInfo) -> Void)?
    internal var voteFinalPageUpdate: ((WKRPage) -> Void)?

    // MARK: - User Interface

    public weak var webView: WKRUIWebView! {
        didSet {
            pageNavigation = newPageNavigation()
            webView.navigationDelegate = pageNavigation
        }
    }
    internal let alertView = WKRUIAlertView()

    // MARK: - Initialization

    public init(networkConfig: WKRPeerNetworkConfig,
                            stateUpdate: @escaping ((WKRGameState, WKRFatalError?) -> Void),
                            pointsUpdate: @escaping ((Int) -> Void),
                            linkCountUpdate: @escaping ((Int) -> Void),
                            logEvent: @escaping ((String, [String: Any]?) -> Void)) {

        self.stateUpdate = stateUpdate
        self.pointsUpdate = pointsUpdate
        self.linkCountUpdate = linkCountUpdate
        self.logEvent = logEvent

        let setup = networkConfig.create()
        localPlayer = setup.player
        peerNetwork = setup.network

        game = WKRGame(localPlayer: localPlayer, isSolo: peerNetwork is WKRSoloNetwork)
        if localPlayer.isHost {
            configure(game: game)
        }

        configure(network: peerNetwork)

        peerNetwork.send(object: WKRCodable(self.localPlayer))
    }

    deinit {
        alertView.removeFromSuperview()
    }

    // MARK: - View Controller Closures

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
        game.localResultsUpdated = { [weak self] results in
            if self?.gameState == .results || self?.gameState == .race {
                infoUpdate(results)
            }
        }
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

    internal func errorOccurred(_ error: WKRFatalError) {
        isFailing = true
        let codable = WKRCodable(enum: error)
        receivedEnum(codable, from: localPlayer.profile)
        if error == .configCreationFailed && localPlayer.isHost {
            peerNetwork.send(object: codable)
        }
        localPlayer.state = .quit
        peerNetwork.send(object: WKRCodable(localPlayer))
        stateUpdate(gameState, error)
        peerNetwork.disconnect()
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
