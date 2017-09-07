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

    // MARK: - Properties

    var isPlayerHost = false
    var gameState = WKRGameState.preMatch

    #if MULTIWINDOWDEBUG
    //swiftlint:disable:next identifier_name
    var _playerName: String!
    #endif

    var session: MCSession!
    var finalPage: WKRPage? {
        didSet {
            title = finalPage?.title?.uppercased()
        }
    }
    var manager: WKRManager!

    // MARK: - User Interface

    var alertView: WKRUIAlertView!
    var bottomConstraint: NSLayoutConstraint!

    let thinLine = UIView()
    let webView = WKRUIWebView()
    let progressView = WKRUIProgressView()

    var flagBarButtonItem: UIBarButtonItem!
    var quitBarButtonItem: UIBarButtonItem!

    // MARK: - View Controllers

    weak var activeViewController: UIViewController?
    weak var alertController: UIAlertController? {
        didSet { activeViewController = alertController }
    }
    weak var lobbyViewController: LobbyViewController? {
        didSet { activeViewController = lobbyViewController }
    }
    weak var votingViewController: VotingViewController? {
        didSet { activeViewController = votingViewController }
    }
    weak var resultsViewController: ResultsViewController? {
        didSet { activeViewController = resultsViewController }
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

    // MARK: - User Actions

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
            self.manager.player(.forfeited)
        }
        alertController.addAction(forfeitAction)

        present(alertController, animated: true, completion: nil)
        self.alertController = alertController
    }

    @IBAction func quitButtonPressed(_ sender: Any) {
        let alertController = quitAlertController(raceStarted: true)
        present(alertController, animated: true, completion: nil)
        self.alertController = alertController
    }

    func quitAlertController(raceStarted: Bool) -> UIAlertController {
        var message = "Are you sure you want to quit? You will be disconnected from the match and returned to the menu."
        if raceStarted {
            message += " Press the forfeit button to give up on the race but stay in the match."
        }

        let alertController = UIAlertController(title: "Leave The Match?", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Keep Playing", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        if raceStarted {
            let forfeitAction = UIAlertAction(title: "Forfeit Race", style: .default) { _ in
                self.manager.player(.forfeited)
            }
            alertController.addAction(forfeitAction)
        }
        let quitAction = UIAlertAction(title: "Quit Match", style: .destructive) { _ in
            self.manager.player(.quit)
            self.navigationController?.navigationController?.popToRootViewController(animated: true)
        }
        alertController.addAction(quitAction)
        return alertController
    }
    //swiftlint:enable line_length

    deinit {
        alertView?.removeFromSuperview()
    }

}
