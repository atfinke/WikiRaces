//
//  GameViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import UIKit
import GameKit
import MultipeerConnectivity

import WKRKit
import WKRUIKit

class GameViewController: UIViewController {

    // MARK: - Types

    enum Segue: String {
        case showPlayers
        case showVoting
        case showResults
    }

    // MARK: - Properties

    var isPlayerHost = false
    #if MULTIWINDOWDEBUG
    //swiftlint:disable:next identifier_name
    var _playerName: String!
    #endif

    var session: MCSession!
    var manager: WKRManager!

    // MARK: - User Interface

    var alertView: WKRUIAlertView!
    var bottomConstraint: NSLayoutConstraint!

    let thinLine = UIView()
    let webView = WKRUIWebView()
    let progressView = WKRUIProgressView()

    // MARK: - View Controllers

    weak var activeViewController: UIViewController?
    weak var votingViewController: VotingViewController? {
        didSet {
            if let viewController = votingViewController {
                activeViewController = viewController
            }
        }
    }
    weak var playersViewController: PlayersViewController? {
        didSet {
            if let viewController = playersViewController {
                activeViewController = viewController
            }
        }
    }
    weak var resultsViewController: ResultsViewController? {
        didSet {
            if let viewController = resultsViewController {
                activeViewController = viewController
            }
        }
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupManager()
        setupInterface()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if manager.gameState == .preMatch {
            performSegue(.showPlayers)
            setupAlertView()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        _debugLog(segue)
        if segue.identifier == Segue.showPlayers.rawValue {
            guard let navigationController = segue.destination as? UINavigationController,
                let destination = navigationController.rootViewController as? PlayersViewController else {
                fatalError()
            }

            destination.didFinish = {
                DispatchQueue.main.async {
                    self.playersViewController?.dismiss(animated: true, completion: {
                        self.playersViewController = nil
                    })
                }
            }

            destination.startButtonPressed = {
                self.manager.host(.startedGame)
                destination.didFinish?()
            }

            destination.isPlayerHost = isPlayerHost
            destination.isPreMatch = manager.gameState == .preMatch
            destination.displayedPlayers = manager.allPlayers

            self.playersViewController = destination
        } else if segue.identifier == Segue.showVoting.rawValue {
            guard let navigationController = segue.destination as? UINavigationController,
                let destination = navigationController.rootViewController as? VotingViewController else {
                    fatalError()
            }

            destination.playerVoted = { page in
                _debugLog(page)
                self.manager.player(.voted(page))
            }

            if let votingInfo = manager?.votingInfo {
                destination.updateVotingInfo(to: votingInfo)
            }

            self.votingViewController = destination
        } else if segue.identifier == Segue.showResults.rawValue {
            guard let navigationController = segue.destination as? UINavigationController,
                let destination = navigationController.rootViewController as? ResultsViewController else {
                    fatalError()
            }

            destination.state = manager.gameState
            destination.resultsInfo = manager.hostResultsInfo
            destination.isPlayerHost = isPlayerHost
            self.resultsViewController = destination
        }
    }

    deinit {
        alertView?.removeFromSuperview()
    }

}
