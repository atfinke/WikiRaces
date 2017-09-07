//
//  ResultsViewController+TableView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

extension ResultsViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsInfo?.playerCount ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //swiftlint:disable:next line_length
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? ResultsTableViewCell,
            let resultsInfo = resultsInfo else {
                fatalError()
        }
        configure(cell: cell, with: resultsInfo, at: indexPath.row)
        return cell
    }

    private func configure(cell: ResultsTableViewCell, with resultsInfo: WKRResultsInfo, at index: Int) {
        switch state {
        case .results, .hostResults:
            let player = resultsInfo.player(at: index)
            cell.playerLabel.text = player.name
            cell.isShowingActivityIndicatorView = false
            cell.accessoryType = (readyStates?.playerReady(player) ?? false) ? .checkmark : .none

            if player.state == .racing {
                cell.isShowingActivityIndicatorView = true
            } else if player.state == .foundPage {
                cell.detailLabel.text = DurationFormatter.string(for: player.raceHistory?.duration)
            } else {
                cell.detailLabel.text = player.state.text
            }
        case .points:
            let points = resultsInfo.pointsInfo(at: index)
            cell.isShowingActivityIndicatorView = false
            cell.playerLabel.text = points.player.name
            cell.accessoryType = .none
            if points.points == 1 {
                cell.detailLabel.text = points.points.description + " PT"
            } else {
                cell.detailLabel.text = points.points.description + " PTS"
            }
        default:
            fatalError()
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let resultsInfo = resultsInfo else {
            return
        }
        let player = resultsInfo.player(at: indexPath.row)
        performSegue(withIdentifier: "showHistory", sender: player)
    }

}
