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

    private var historyViewController: HistoryViewController?
    private var isAnimatingPointsStateChange = false

    var readyButtonPressed: (() -> Void)?
    var quitAlertController: UIAlertController?
    var addPlayersViewController: UIViewController?

    // MARK: - Game States

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
            updatedState(oldState: oldValue)
        }
    }

    var readyStates: WKRReadyStates? {
        didSet {
            if state == .hostResults {
                updateTableView()
            }
        }
    }

    var resultsInfo: WKRResultsInfo? {
        didSet {
            updateTableView()
            updateHistoryController()
        }
    }

    var timeRemaining: Int = 100 {
        didSet {
            updatedTime(oldTime: oldValue)
        }
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        registerTableView(for: self)
        overlayButtonTitle = "Ready up"

        guideLabel.text = "TAP PLAYER TO VIEW LIVE PROGRESS"
        descriptionLabel.text = "WAITING FOR PLAYERS TO FINISH"

        tableView.isUserInteractionEnabled = true
        tableView.register(ResultsTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Actions

    @IBAction func quitButtonPressed(_ sender: Any) {
        PlayerAnalytics.log(event: .userAction(#function))
        guard let alertController = quitAlertController else {
            NotificationCenter.default.post(name: NSNotification.Name("PlayerQuit"), object: nil)
            PlayerAnalytics.log(event: .backupQuit, attributes: ["GameState": state.rawValue.description as Any])
            return
        }
        present(alertController, animated: true, completion: nil)
        PlayerAnalytics.log(presentingOf: alertController, on: self)
    }

    @IBAction func addPlayersBarButtonItemPressed(_ sender: Any) {
        PlayerAnalytics.log(event: .userAction(#function))
        guard let controller = addPlayersViewController else { return }
        present(controller, animated: true, completion: nil)
        PlayerAnalytics.log(event: .hostStartMidMatchInviting)
        PlayerAnalytics.log(presentingOf: controller, on: self)
    }

    override func overlayButtonPressed() {
        PlayerAnalytics.log(event: .userAction(#function))

        navigationItem.leftBarButtonItem?.isEnabled = false
        readyButtonPressed?()
        isOverlayButtonHidden = true

        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }

        PlayerAnalytics.log(event: .pressedReadyButton, attributes: ["Time": timeRemaining as Any])
    }

    // MARK: - Game Updates

    private func updatedState(oldState: WKRGameState) {
        if state == .results || state == .hostResults {
            title = "RESULTS"
            tableView.isUserInteractionEnabled = true
            updateTableView()
        } else {
            title = "STANDINGS"
            tableView.isUserInteractionEnabled = false
            if let activeViewController = presentedViewController,
                type(of: activeViewController) != UIAlertController.self {
                dismiss(animated: true, completion: nil)
            }

            if oldState != .points {
                isAnimatingPointsStateChange = true
                flashItems(items: [tableView], duration: 1.0) {
                    self.isAnimatingPointsStateChange = false
                    self.updateTableView()
                }
            } else {
                self.updateTableView()
            }

            UIView.animate(withDuration: 0.5, animations: {
                self.guideLabel.alpha = 0.0
                self.descriptionLabel.alpha = 0.0
            })
        }
    }

    private func updatedTime(oldTime: Int) {
        tableView.isUserInteractionEnabled = true
        if oldTime == 100 {
            flashItems(items: [guideLabel, descriptionLabel], duration: 0.75) {
                self.guideLabel.text = "TAP PLAYER TO VIEW HISTORY"
                self.descriptionLabel.text = "NEXT ROUND STARTS IN " + self.timeRemaining.description + " S"
            }
        } else {
            descriptionLabel.text = "NEXT ROUND STARTS IN " + timeRemaining.description + " S"
        }
    }

    // MARK: - Helpers

    private func updateTableView() {
        guard !isAnimatingPointsStateChange else { return }
        tableView.reloadData()
    }

    func updateHistoryController() {
        guard let player = historyViewController?.player,
            let updatedPlayer = resultsInfo?.updatedPlayer(for: player) else {
                return
        }
        historyViewController?.player = updatedPlayer
    }

    func showReadyUpButton(_ showReady: Bool) {
        navigationItem.leftBarButtonItem?.isEnabled = showReady
        isOverlayButtonHidden = !showReady
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        PlayerAnalytics.log(event: .userAction(#function))
        guard let destinationNavigationController = segue.destination as? UINavigationController,
            let destination = destinationNavigationController.rootViewController as? HistoryViewController,
            let player = sender as? WKRPlayer else {
                fatalError()
        }

        destination.player = player
        historyViewController = destination
    }

}
