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

    // MARK: - Game Properties

    var isPlayerHost = false
    var isPlayerQuitting = false

    var needsUIConfigured = true
    var gameState = WKRGameState.preMatch

    var manager: WKRManager!
    var finalPage: WKRPage? {
        didSet {
            title = finalPage?.title?.uppercased()
        }
    }

    #if MULTIWINDOWDEBUG
    var windowName: String!
    #else
    var serviceType: String!
    var session: MCSession!
    #endif

    // MARK: - User Interface

    let thinLine = UIView()
    let webView = WKRUIWebView()
    let progressView = WKRUIProgressView()

    var alertView: WKRUIAlertView!
    var flagBarButtonItem: UIBarButtonItem!
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
        setupManager()
        setupInterface()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if needsUIConfigured {
            needsUIConfigured = false
            setupAlertView()
            if !isPlayerHost {
                UIView.animate(withDuration: 0.5, animations: {
                    self.connectingLabel.alpha = 1.0
                    self.activityIndicatorView.alpha = 1.0
                })
            }
        }
        if manager.gameState == .preMatch && isPlayerHost {
            manager.player(.startedGame)
            PlayerAnalytics.log(event: .hostStartedMatch)
        }
    }

    // MARK: - User Actions

    @IBAction func flagButtonPressed(_ sender: Any) {
        //swiftlint:disable:next line_length
        let alertController = UIAlertController(title: "Forfeit The Round?", message: "Are you sure you want to forfeit? Try tapping the help button for a peek at the final article before making up your mind.", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Keep Playing", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        let helpAction = UIAlertAction(title: "Help", style: .default) { _ in
            self.manager.player(.neededHelp)
            self.performSegue(.showHelp)
            PlayerAnalytics.log(event: .usedHelp)
        }
        alertController.addAction(helpAction)

        let reloadAction = UIAlertAction(title: "Reload Page", style: .default) { _ in
            self.webView.reload()
        }
        alertController.addAction(reloadAction)

        let forfeitAction = UIAlertAction(title: "Forfeit Round", style: .destructive) { _ in
            self.manager.player(.forfeited)
            PlayerAnalytics.log(event: .forfeited)
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

    deinit {
        alertView?.removeFromSuperview()
        NotificationCenter.default.removeObserver(self)
    }

}
