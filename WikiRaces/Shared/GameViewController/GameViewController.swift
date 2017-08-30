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

class GameViewController: UIViewController {

    // MARK: - Types

    enum Segue: String {
        case showPlayers
        case showVoting
        case showResults
        case showHelp
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

    @IBOutlet weak var flagBarButtonItem: UIBarButtonItem!
    lazy var loadingBarButtonItem: UIBarButtonItem = {
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityView.sizeToFit()
        activityView.startAnimating()
        return UIBarButtonItem(customView: activityView)
    }()

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

        guard let navigationController = segue.destination as? UINavigationController,
            let unwrappedSegueIdentifier = segue.identifier,
            let segueIdentifier = Segue(rawValue: unwrappedSegueIdentifier) else {
                fatalError("Unknown segue \(String(describing: segue.identifier))")
        }

        switch segueIdentifier {
        case .showPlayers:
            guard let destination = navigationController.rootViewController as? PlayersViewController else {
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

            destination.addPlayersButtonPressed = { viewController in
                self.manager.presentNetworkInterface(on: viewController)
            }

            destination.isPlayerHost = isPlayerHost
            destination.isPreMatch = manager.gameState == .preMatch
            destination.displayedPlayers = manager.allPlayers

            self.playersViewController = destination
        case .showVoting:
            guard let destination = navigationController.rootViewController as? VotingViewController else {
                fatalError()
            }

            navigationItem.leftBarButtonItem = flagBarButtonItem
            navigationItem.leftBarButtonItem?.isEnabled = true
            navigationItem.rightBarButtonItem?.isEnabled = true

            destination.playerVoted = { page in
                self.manager.player(.voted(page))
            }

            if let votingInfo = manager?.votingInfo {
                destination.updateVotingInfo(to: votingInfo)
            }

            self.votingViewController = destination
        case .showResults:
            guard let destination = navigationController.rootViewController as? ResultsViewController else {
                fatalError()
            }

            destination.state = manager.gameState
            destination.resultsInfo = manager.hostResultsInfo
            destination.isPlayerHost = isPlayerHost
            self.resultsViewController = destination
        case .showHelp:
            guard let destination = navigationController.rootViewController as? HelpViewController else {
                fatalError()
            }

            destination.linkTapped = {
                self.manager.enqueue(message: "Links disabled in help", duration: 2.0)
            }

            destination.url = manager.finalPageURL
            self.activeViewController = destination
        }
    }

    // MARK: - User Actions

    func disableBarButtonItems() {
        navigationItem.leftBarButtonItem = loadingBarButtonItem
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    //swiftlint:disable line_length
    @IBAction func flagButtonPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Forfeit The Round?", message: "Are you sure you want to forfeit? Try tapping the help button for a peek at the final article before making up your mind.", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Resume", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        let helpAction = UIAlertAction(title: "Help", style: .default) { _ in
            self.manager.player(.neededHelp)
            self.performSegue(.showHelp)
        }
        alertController.addAction(helpAction)

        let forfeitAction = UIAlertAction(title: "Forfeit Round", style: .destructive) { _ in
            self.disableBarButtonItems()
            self.manager.player(.forfeited)
        }
        alertController.addAction(forfeitAction)

        present(alertController, animated: true, completion: nil)
    }

    @IBAction func quitButtonPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Leave The Match?", message: "Are you sure you want to quit? You will be disconnected from the match and returned to the menu. Press the forfeit button to give up on the round but stay in the match.", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Resume", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        let forfeitAction = UIAlertAction(title: "Forfeit Round", style: .default) { _ in
            self.disableBarButtonItems()
            self.manager.player(.forfeited)
        }
        alertController.addAction(forfeitAction)

        let quitAction = UIAlertAction(title: "Quit Match", style: .destructive) { _ in
            self.disableBarButtonItems()
            self.manager.player(.quit)
        }
        alertController.addAction(quitAction)

        present(alertController, animated: true, completion: nil)
    }
    //swiftlint:enable line_length

    deinit {
        alertView?.removeFromSuperview()
    }

}
