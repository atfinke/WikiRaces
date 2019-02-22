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

    let webView = WKRUIWebView()
    let progressView = WKRUIProgressView()
    let navigationBarBottomLine = UIView()

    var helpBarButtonItem: UIBarButtonItem!
    var quitBarButtonItem: UIBarButtonItem!

    @IBOutlet weak var connectingLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

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
        setupGameManager()
        setupInterface()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isInterfaceConfigured {
            isInterfaceConfigured = true
            if !networkConfig.isHost {
                UIView.animate(withDuration: 0.5, animations: {
                    self.connectingLabel.alpha = 1.0
                    self.activityIndicatorView.alpha = 1.0
                })
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
        }
        if gameManager.gameState == .preMatch && networkConfig.isHost {
            gameManager.player(.startedGame)
            if case let .mpc(_, session, _)? = networkConfig {
                PlayerMetrics.log(event: .hostStartedMatch,
                                    attributes: ["ConnectedPeers": session.connectedPeers.count])
            }
        }
    }

    // MARK: - User Actions

    @IBAction func helpButtonPressed() {
        PlayerMetrics.log(event: .userAction(#function))
        showHelp()
    }

    @IBAction func quitButtonPressed() {
        PlayerMetrics.log(event: .userAction(#function))

        let alertController = quitAlertController(raceStarted: true)
        present(alertController, animated: true, completion: nil)
        self.alertController = alertController
    }

    func showHelp() {
        PlayerMetrics.log(event: .userAction("flagButtonPressed:help"))
        PlayerMetrics.log(event: .usedHelp, attributes: ["Page": self.finalPage?.title as Any])
        gameManager.player(.neededHelp)
        performSegue(.showHelp)
    }

    func reloadPage() {
        PlayerMetrics.log(event: .userAction("flagButtonPressed:reload"))
        self.webView.reload()
    }

}
