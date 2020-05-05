//
//  StatsPlayersViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit

class StatsPlayersViewController: UITableViewController {

    // MARK: - Properties -

    let players: [(String, Int)]

    // MARK: - Initalization -

    init(mpc: Bool) {
        let key: String
        if mpc {
            key = "PlayersArray"
        } else {
            key = "GKPlayersArray"
        }
        let players = UserDefaults.standard.stringArray(forKey: key) ?? []

        var count = [String: Int]()
        for player in players {
            if let existing = count[player] {
                count[player] = existing + 1
            } else {
                count[player] = 1
            }
        }
        self.players = count.sorted { lhs, rhs -> Bool in
            return lhs.value > rhs.value
        }

        super.init(style: .plain)
        title = "Players Raced"
        tableView.allowsSelection = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UITableViewDataSource -

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, players.count)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if players.isEmpty {
            cell.textLabel?.text = "No Players Raced"
            cell.textLabel?.textColor = .secondaryLabel
        } else {
            let item = players[indexPath.row]
            cell.textLabel?.text = item.0
            cell.detailTextLabel?.text = item.1.description + "x"
        }
        return cell
    }

}
