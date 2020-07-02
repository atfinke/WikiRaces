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

final internal class GameViewController: UIViewController {

    // MARK: - Types

    enum TransitionState: Equatable {
        enum QuitState {
            case waiting, inProgress
        }
        case none, inProgress, quitting(QuitState)
    }

    // MARK: - Game Properties

    var transitionState = TransitionState.none {
        didSet {
            PlayerAnonymousMetrics.log(event: .gameState("TransitionState: \(transitionState)"))
        }
    }
    var isErrorPresented = false
    var isConfigured = false

    var timeRaced = 0
    var raceTimer: Timer?
    var gameState = WKRGameState.preMatch

    var finalPage: WKRPage? {
        didSet {
            title = finalPage?.title?.uppercased()
        }
    }

    var gameManager: WKRGameManager!

    let networkConfig: WKRPeerNetworkConfig
    let gameSettings: WKRGameSettings

    var statRaceType: PlayerStatsManager.RaceType? {
        return PlayerStatsManager.RaceType(networkConfig)
    }

    // MARK: - User Interface

    var webView: WKRUIWebView?
    let progressView = WKRUIProgressView()
    let navigationBarBottomLine = UIView()

    var helpBarButtonItem: UIBarButtonItem!
    var quitBarButtonItem: UIBarButtonItem!

    let connectingLabel = UILabel()
    let activityIndicatorView = UIActivityIndicatorView(style: .large)

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

    // MARK: - Initalization -

    init(network: WKRPeerNetworkConfig, settings: WKRGameSettings) {
        self.networkConfig = network
        self.gameSettings = settings
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if Defaults.isFastlaneSnapshotInstance {
            setupInterface()
            let url = URL(string: "https://en.m.wikipedia.org/wiki/Walt_Disney_World_Monorail_System")!
            prepareForScreenshots(for: url)
        } else {
            setupGameManager()
            setupInterface()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        if Defaults.isFastlaneSnapshotInstance {
//            return
//        }

        if !isConfigured {
            isConfigured = true
            initalConfiguration()
        }

        if gameManager.gameState == .preMatch && networkConfig.isHost {
            gameManager.player(.startedGame)
            switch networkConfig {
            case .solo:
                PlayerAnonymousMetrics.log(event: .hostStartedMatch, attributes: nil)
            case .gameKitPrivate(let match, _), .gameKitPublic(let match, _):
                PlayerAnonymousMetrics.log(event: .hostStartedMatch,
                                           attributes: ["ConnectedPeers": match.players.count - 1])
            default: break
            }
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let textColor: UIColor = .wkrTextColor(for: traitCollection)
        navigationBarBottomLine.backgroundColor = textColor
        connectingLabel.textColor = textColor
        view.backgroundColor = .wkrBackgroundColor(for: traitCollection)
        activityIndicatorView.color = .wkrActivityIndicatorColor(for: traitCollection)
    }

    private func initalConfiguration() {
        let logEvents: [WKRLogEvent]
        if networkConfig.isHost {
            if case .solo = networkConfig {
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
        logEvents.forEach { logEvent($0) }

        switch networkConfig {
        case .solo:
            PlayerStatsManager.shared.connected(to: [], raceType: .solo)
        case .gameKitPrivate(let match, _):
            let playerNames = match.players.map { player -> String in
                return player.alias
            }
            PlayerStatsManager.shared.connected(to: playerNames, raceType: .private)
        case .gameKitPublic(let match, _):
            let playerNames = match.players.map { player -> String in
                return player.alias
            }
            PlayerStatsManager.shared.connected(to: playerNames, raceType: .public)
        default:
            break
        }
    }

    deinit {
        let alertView = gameManager.alertView
        DispatchQueue.main.async {
            alertView.removeFromSuperview()
        }
    }

    // MARK: - User Actions

    @objc
    func helpButtonPressed() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        if gameSettings.other.isHelpEnabled {
            showHelp()
        } else {
            let controller = UIAlertController(
                title: "Custom Race",
                message: "The host disabled help for this race",
                preferredStyle: .alert)
            controller.addCancelAction(title: "Ok")
            present(controller, animated: true, completion: nil)
        }
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

        let navController = WKRUINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true, completion: nil)

        PlayerAnonymousMetrics.log(event: .userAction("flagButtonPressed:help"))
        PlayerAnonymousMetrics.log(event: .usedHelp,
                                   attributes: ["Page": self.finalPage?.title as Any])
        if let raceType = statRaceType {
            let stat: PlayerDatabaseStat
            switch raceType {
            case .private: stat = .mpcHelp
            case .public: stat = .gkHelp
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
