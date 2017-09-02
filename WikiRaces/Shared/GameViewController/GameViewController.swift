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

    var flagBarButtonItem: UIBarButtonItem!
    var quitBarButtonItem: UIBarButtonItem!

    // MARK: - View Controllers

    weak var activeViewController: UIViewController?
    weak var votingViewController: VotingViewController? {
        didSet {
            if let viewController = votingViewController {
                activeViewController = viewController
            }
        }
    }
    weak var lobbyViewController: LobbyViewController? {
        didSet {
            if let viewController = lobbyViewController {
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
    }

    @IBAction func quitButtonPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Leave The Match?", message: "Are you sure you want to quit? You will be disconnected from the match and returned to the menu. Press the forfeit button to give up on the round but stay in the match.", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Resume", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        let forfeitAction = UIAlertAction(title: "Forfeit Round", style: .default) { _ in
            self.manager.player(.forfeited)
        }
        alertController.addAction(forfeitAction)

        let quitAction = UIAlertAction(title: "Quit Match", style: .destructive) { _ in
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
