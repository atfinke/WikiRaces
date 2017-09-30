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
            let raceResults = resultsInfo.raceResults(at: index)
            cell.playerLabel.text = raceResults.player.name
            cell.isShowingActivityIndicatorView = false
            cell.accessoryType = (readyStates?.playerReady(raceResults.player) ?? false) ? .checkmark : .none

            if raceResults.playerState == .racing {
                cell.isShowingActivityIndicatorView = true
            } else if raceResults.playerState == .foundPage {
                cell.detailLabel.text = DurationFormatter.string(for: raceResults.player.raceHistory?.duration)
            } else {
                cell.detailLabel.text = raceResults.playerState.text
            }
        case .points:
            let sessionResults = resultsInfo.sessionResults(at: index)
            cell.isShowingActivityIndicatorView = false
            cell.playerLabel.text = (index + 1).description + ". " + sessionResults.profile.name
            cell.accessoryType = .none
            if sessionResults.points == 1 {
                cell.detailLabel.text = sessionResults.points.description + " PT"
            } else {
                cell.detailLabel.text = sessionResults.points.description + " PTS"
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
        let raceResults = resultsInfo.raceResults(at: indexPath.row)
        performSegue(withIdentifier: "showHistory", sender: raceResults.player)

        PlayerAnalytics.log(event: .openedHistory)
    }

}
