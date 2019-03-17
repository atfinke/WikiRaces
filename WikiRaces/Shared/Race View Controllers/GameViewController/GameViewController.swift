//
//  GameViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import MultipeerConnectivity

import WKRKit
import WKRUIKit

internal class GameViewController: UIViewController {

    // MARK: - Game Properties

    var isPlayerQuitting = false
    var isInterfaceConfigured = false

    var timeRaced = 0
    var raceTimer: Timer?
    var gameState = WKRGameState.preMatch

    var finalPage: WKRPage? {
        didSet {
            title = finalPage?.title?.uppercased()
        }
    }

    var gameManager: WKRGameManager!
    var networkConfig: WKRPeerNetworkConfig!

    var statRaceType: StatsHelper.RaceType? {
        return StatsHelper.RaceType(networkConfig)
    }

    // MARK: - User Interface

    var webView: WKRUIWebView?
    let progressView = WKRUIProgressView()
    let navigationBarBottomLine = UIView()

    var helpBarButtonItem: UIBarButtonItem!
    var quitBarButtonItem: UIBarButtonItem!

    let connectingLabel = UILabel()
    let activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)

    // MARK: - View Controllers

    var activeViewController: UIViewController?
    var alertController: UIAlertController? {
        didSet { activeViewController = alertController }
    }
    var votingViewController: VotingViewController? {
        didSet { activeViewController = votingViewController }
    }
    var resultsViewController: ResultsViewController? {
        didSet { activeViewController = resultsViewController }
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if !UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            setupGameManager()
        }

        setupInterface()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            webView?.alpha = 1.0
            return
        }

        if !isInterfaceConfigured {
            isInterfaceConfigured = true

            let logEvents: [WKRLogEvent]
            if networkConfig.isHost {
                if case .solo? = networkConfig {
                    logEvents = WKRSeenFinalArticlesStore.localLogEvents()
                } else {
                    logEvents = WKRSeenFinalArticlesStore.hostLogEvents()
                }
            } else {
                UIView.animate(withDuration: 0.5, animations: {
                    self.connectingLabel.alpha = 1.0
                    self.activityIndicatorView.alpha = 1.0
                })
                logEvents = WKRSeenFinalArticlesStore.localLogEvents()
            }

            if case let .mpc(_, session, _)? = networkConfig {
                // Due to low usage, not accounting for players joining mid session
                let playerNames = session.connectedPeers.filter({ peerID -> Bool in
                    return peerID != session.myPeerID
                }).map({ peerID -> String in
                    return peerID.displayName
                })
                StatsHelper.shared.connected(to: playerNames, raceType: .mpc)
            } else if case let .gameKit(match, _)? = networkConfig {
                let playerNames = match.players.map({ player -> String in
                    return player.alias
                })
                StatsHelper.shared.connected(to: playerNames, raceType: .gameKit)
            }

            logEvents.forEach { logEvent($0) }
        }
        if gameManager.gameState == .preMatch && networkConfig.isHost {
            gameManager.player(.startedGame)
            if case let .mpc(_, session, _)? = networkConfig {
                PlayerAnonymousMetrics.log(event: .hostStartedMatch,
                                    attributes: ["ConnectedPeers": session.connectedPeers.count])
            }
        }
    }

    // MARK: - User Actions

    @objc
    func helpButtonPressed() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        showHelp()
    }

    @objc
    func quitButtonPressed() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        let alertController = quitAlertController(raceStarted: true)
        present(alertController, animated: true, completion: nil)
        self.alertController = alertController
    }

    func showHelp() {
        gameManager.player(.neededHelp)

        let controller = HelpViewController()
        controller.url = gameManager.finalPageURL
        controller.linkTapped = { [weak self] in
            self?.gameManager.enqueue(message: "Links disabled in help",
                                      duration: 2.0,
                                      isRaceSpecific: true,
                                      playHaptic: true)
        }
        self.activeViewController = controller

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true, completion: nil)

        PlayerAnonymousMetrics.log(event: .userAction("flagButtonPressed:help"))
        PlayerAnonymousMetrics.log(event: .usedHelp,
                          attributes: ["Page": self.finalPage?.title as Any])
        if let raceType = statRaceType {
            let stat: PlayerStat
            switch raceType {
            case .mpc: stat = .mpcHelp
            case .gameKit: stat = .gkHelp
            case .solo: stat = .soloHelp
            }
            stat.increment()
        }
    }

    func reloadPage() {
        PlayerAnonymousMetrics.log(event: .userAction("flagButtonPressed:reload"))
        self.webView?.reload()
    }

    // Used for screenshots / fastlane
    func prepareForScreenshots(for url: URL) {
        webView?.load(URLRequest(url: url))
        title = "Star Wars: Galaxy's Edge".uppercased()
    }

}
