//
//  ResultsViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit

class ResultsViewController: CenteredTableViewController {

    // MARK: - Properties

    var isPlayerHost = false
    var isPlayerReady = false

    var players: [WKRPlayer]? {
        didSet {
            resultsInfo?.updatePlayers(players ?? [])
            tableView.reloadData()
            updateHistoryController()
        }
    }

    var state: WKRGameState = .results {
        didSet {
            _debugLog(state)
            tableView.reloadData()
            updateOverlayButtonState()

            if state == .results {
                title = "RESULTS"
            } else {
                title = "STANDINGS"
            }
        }
    }

    var readyStates: WKRReadyStates? {
        didSet {
            _debugLog(resultsInfo)
            tableView.reloadData()
        }
    }

    var resultsInfo: WKRResultsInfo? {
        didSet {
            _debugLog(resultsInfo)
            tableView.reloadData()
            updateHistoryController()
        }
    }

    var timeRemaining: Int = 100 {
        didSet {
            _debugLog(timeRemaining)
            if timeRemaining == 0 {
                resultsEnded()
            } else {
                tableView.isUserInteractionEnabled = true
                descriptionLabel.text = "VOTING STARTS IN " + timeRemaining.description + " S"
            }
        }
    }

    let footerCellReuseIdentifier = "disclaimerCell"

    private var historyViewController: HistoryViewController?

    var readyButtonPressed: (() -> Void)?
    var addPlayersButtonPressed: ((UIViewController) -> Void)?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        _debugLog(nil)

        registerTableView(for: self)
        tableView.isUserInteractionEnabled = true

        descriptionLabel.text = "WAITING FOR PLAYERS"
        descriptionLabel.textColor = UIColor.wkrTextColor

        tableView.register(ResultsTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.register(FooterButtonTableViewCell.self, forCellReuseIdentifier: footerCellReuseIdentifier)

        overlayButtonTitle = "Ready up"
        isOverlayButtonHidden = true
        updateOverlayButtonState()
    }

    override func overlayButtonPressed() {
        isPlayerReady = true
        readyButtonPressed?()
        UIView.animate(withDuration: 0.5) {
            self.isOverlayButtonHidden = true
        }
    }

    func updateOverlayButtonState() {
        guard isViewLoaded && state == .hostResults && !isPlayerReady else {
            return
        }
        UIView.animate(withDuration: 0.5, delay: 5.0, options: .beginFromCurrentState, animations: {
            self.isOverlayButtonHidden = false
        }, completion: nil)
    }

    // MARK: - Helpers

    @objc func footerButtonPressed() {
        _debugLog(nil)
        addPlayersButtonPressed?(self)
    }

    func resultsEnded() {
        _debugLog(nil)
        UIView.animate(withDuration: 0.5, animations: {
            self.descriptionLabel.alpha = 0.0
        })
    }

    func updateHistoryController() {
        if let currentPlayer = historyViewController?.player,
            let updatedPlayer = resultsInfo?.player(for: currentPlayer.profile) {
            historyViewController?.player = updatedPlayer
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationNavigationController = segue.destination as? UINavigationController else {
            return
        }
        if let destination = destinationNavigationController.rootViewController as? HistoryViewController,
            let player = sender as? WKRPlayer {
            destination.player = player
            historyViewController = destination
        } else {
            fatalError()
        }

    }

}
