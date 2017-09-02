//
//  LobbyViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

class LobbyViewController: UIViewController {

    // MARK: - Properties

    var didFinish: (() -> Void)?
    var startButtonPressed: (() -> Void)?
    var addPlayersButtonPressed: ((UIViewController) -> Void)?

    let tableView = UITableView()
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))

    let playerCellReuseIdentifier = "playerCell"
    let footerCellReuseIdentifier = "disclaimerCell"

    var isPlayerHost = false
    var isPreMatch = false

    var displayedPlayers = [WKRPlayer]()

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
    }

    // MARK: - WKRGame

    func updatedConnectedPlayers(players: [WKRPlayer]) {
        _debugLog(players)
        var removedPlayers = 0
        for player in players {
            if let index = displayedPlayers.index(of: player) {
                if displayedPlayers[index].state != player.state {
                    _debugLog("updating player")
                    displayedPlayers[index].state = player.state
                    tableView.reloadRows(at: [IndexPath(row: index)], with: .none)
                }
            }
        }
        for (index, player) in displayedPlayers.map({ $0 }).enumerated() {
            if !players.contains(player) {
                _debugLog("removed player")
                displayedPlayers.remove(at: index - removedPlayers)
                tableView.deleteRows(at: [IndexPath(row: index)], with: .fade)
                removedPlayers += 1
            }
        }
        for player in players {
            if !displayedPlayers.contains(player) {
                _debugLog("adding player")
                displayedPlayers.append(player)
                tableView.insertRows(at: [IndexPath(row: displayedPlayers.count - 1)], with: .automatic)
            }
        }
    }

    // MARK: - Button Pressed

    @IBAction func doneButtonPressed() {
        _debugLog(nil)
        didFinish?()
    }

    @objc func startRaceButtonPressed() {
        _debugLog(nil)
        startButtonPressed?()
    }

    @objc func footerButtonPressed() {
        _debugLog(nil)
        addPlayersButtonPressed?(self)
    }

}
