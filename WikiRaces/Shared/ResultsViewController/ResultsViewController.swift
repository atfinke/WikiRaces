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

    var isPlayerHost = false {
        didSet {
            if isPlayerHost {
                navigationItem.leftBarButtonItem?.isEnabled = false
            } else {
                navigationItem.leftBarButtonItem = nil
            }
        }
    }

    var state: WKRGameState = .results {
        didSet {
            tableView.reloadData()
            if state == .results || state == .hostResults {
                title = "RESULTS"
                tableView.isUserInteractionEnabled = true
            } else {
                title = "STANDINGS"
                tableView.isUserInteractionEnabled = false
                if historyViewController != nil {
                    dismiss(animated: true, completion: nil)
                }
                UIView.animate(withDuration: 0.5) {
                    self.descriptionLabel.alpha = 0.0
                }
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
            tableView.isUserInteractionEnabled = true
            descriptionLabel.text = "VOTING STARTS IN " + timeRemaining.description + " S"
        }
    }

    let footerCellReuseIdentifier = "disclaimerCell"

    private var historyViewController: HistoryViewController?
    @IBOutlet weak var addPlayersBarButtonItem: UIBarButtonItem?

    var quitButtonPressed: ((UIViewController) -> Void)?
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

        overlayButtonTitle = "Ready up"
    }

    // MARK: - Actions

    @IBAction func quitBarButtonItemPressed(_ sender: Any) {
        quitButtonPressed?(self)
    }

    @IBAction func addPlayersBarButtonItemPressed(_ sender: Any) {
        addPlayersButtonPressed?(self)
    }

    override func overlayButtonPressed() {
        navigationItem.leftBarButtonItem?.isEnabled = false
        readyButtonPressed?()
        isOverlayButtonHidden = true
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Helpers

    func resultsEnded() {
        UIView.animate(withDuration: 0.5) {
            self.descriptionLabel.alpha = 0.0
        }
    }

    func updateHistoryController() {
        guard let player = historyViewController?.player,
            let updatedPlayer = resultsInfo?.player(for: player.profile) else {
                return
        }
        historyViewController?.player = updatedPlayer
    }

    func showReadyUpButton(_ showReady: Bool) {
        navigationItem.leftBarButtonItem?.isEnabled = showReady
        isOverlayButtonHidden = false
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationNavigationController = segue.destination as? UINavigationController,
            let destination = destinationNavigationController.rootViewController as? HistoryViewController else {
                fatalError()
        }
        let player = sender as? WKRPlayer
        destination.player = player
        historyViewController = destination
    }

}
