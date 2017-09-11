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

    private let infoLabel = UILabel()
    private var historyViewController: HistoryViewController?

    private var isAnimatingStateChange = false
    var readyButtonPressed: (() -> Void)?
    var quitAlertController: UIAlertController?
    var addPlayersButtonPressed: ((UIViewController) -> Void)?

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

        descriptionLabel.text = "WAITING FOR PLAYERS TO FINISH"
        descriptionLabel.textColor = UIColor.wkrTextColor

        tableView.isUserInteractionEnabled = true
        tableView.register(ResultsTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)

        infoLabel.textAlignment = .center
        infoLabel.textColor = UIColor.wkrLightTextColor
        infoLabel.text = "TAP PLAYER TO VIEW PROGRESS"
        infoLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        infoLabel.adjustsFontSizeToFitWidth = true
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoLabel)

        let constraints = [
            infoLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            infoLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            infoLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Actions

    @IBAction func quitButtonPressed(_ sender: Any) {
        guard let alertController = quitAlertController else { fatalError() }
        present(alertController, animated: true, completion: nil)
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
                isAnimatingStateChange = true
                UIView.animate(withDuration: 0.4, animations: {
                    self.tableView.alpha = 0.0
                    self.infoLabel.alpha = 0.0
                }, completion: { _ in
                    self.isAnimatingStateChange = false
                    self.updateTableView()
                    UIView.animate(withDuration: 0.4, animations: {
                        self.tableView.alpha = 1.0
                    })
                })
            } else {
                self.updateTableView()
            }

            UIView.animate(withDuration: 0.75, animations: {
                self.descriptionLabel.alpha = 0.0
            })
        }
    }

    private func updatedTime(oldTime: Int) {
        tableView.isUserInteractionEnabled = true
        if oldTime == 100 {
            UIView.animate(withDuration: 0.25, animations: {
                self.descriptionLabel.alpha = 0.0
            }, completion: { _ in
                self.descriptionLabel.text = "NEXT ROUND STARTS IN " + self.timeRemaining.description + " S"
                UIView.animate(withDuration: 0.25, animations: {
                    self.descriptionLabel.alpha = 1.0
                })
            })
        } else {
            descriptionLabel.text = "NEXT ROUND STARTS IN " + timeRemaining.description + " S"
        }
    }

    // MARK: - Helpers

    private func updateTableView() {
        guard !isAnimatingStateChange else { return }
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
        guard let destinationNavigationController = segue.destination as? UINavigationController,
            let destination = destinationNavigationController.rootViewController as? HistoryViewController,
            let player = sender as? WKRPlayer else {
                fatalError()
        }

        destination.player = player
        historyViewController = destination
    }

}
