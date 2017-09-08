//
//  LobbyViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit

class LobbyViewController: UIViewController {

    // MARK: - Properties

    var quitAlertController: UIAlertController?

    var startButtonPressed: (() -> Void)?
    var addPlayersButtonPressed: ((UIViewController) -> Void)?

    let startButton = WKRUIButton()

    let tableView = UITableView()
    let overlayLabel = UILabel()
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    var overlayHeightConstraint: NSLayoutConstraint!

    let playerCellReuseIdentifier = "playerCell"
    let footerCellReuseIdentifier = "inviteCell"

    var isPlayerHost = false
    var displayedPlayers = [WKRPlayer]()

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        quitAlertController = nil
    }

    // MARK: - WKRGame

    func updatedConnectedPlayers(players: [WKRPlayer]) {
        var removedPlayers = 0
        for player in players {
            if let index = displayedPlayers.index(of: player) {
                if displayedPlayers[index].state != player.state {
                    displayedPlayers[index].state = player.state
                    tableView.reloadRows(at: [IndexPath(row: index)], with: .none)
                }
            }
        }
        for (index, player) in displayedPlayers.map({ $0 }).enumerated() where !players.contains(player) {
            displayedPlayers.remove(at: index - removedPlayers)
            tableView.deleteRows(at: [IndexPath(row: index)], with: .fade)
            removedPlayers += 1
        }
        for player in players where !displayedPlayers.contains(player) {
            displayedPlayers.append(player)
            tableView.insertRows(at: [IndexPath(row: displayedPlayers.count - 1)], with: .automatic)
        }

        if isViewLoaded && isPlayerHost && players.count > 1 && overlayHeightConstraint.constant != 70 {
            overlayHeightConstraint.constant = 70
            view.layoutIfNeeded()
            startButton.isHidden = false
            overlayLabel.isHidden = true
        }
    }

    // MARK: - Actions

    @IBAction func quitButtonPressed(_ sender: Any) {
        guard let alertController = quitAlertController else { fatalError() }
        present(alertController, animated: true, completion: nil)
    }

    @objc func startRaceButtonPressed() {
        startButtonPressed?()
    }

    @objc func addPlayers() {
        addPlayersButtonPressed?(self)
    }

}
