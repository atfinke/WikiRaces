//
//  PlayersViewController+TableView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

extension PlayersViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isPlayerHost ? displayedPlayers.count + 1 : displayedPlayers.count
    }

    //swiftlint:disable line_length
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == displayedPlayers.count {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: footerCellReuseIdentifier, for: indexPath) as? FooterButtonTableViewCell else { fatalError() }
            cell.button.title = "Add Players"
            //  cell.button.addTarget(self, action: #selector(footerButtonPressed(_:)), for: .touchUpInside)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: playerCellReuseIdentifier, for: indexPath) as? PlayerStateTableViewCell else { fatalError() }
            cell.state = displayedPlayers[indexPath.row].state
            cell.player = displayedPlayers[indexPath.row]
            return cell
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == displayedPlayers.count ? 60.0 : 44.0
    }
}

