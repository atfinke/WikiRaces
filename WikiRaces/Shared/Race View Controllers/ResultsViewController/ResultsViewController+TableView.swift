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
                fatalError("Unable to create cell")
        }
        configure(cell: cell, with: resultsInfo, at: indexPath.row)
        return cell
    }

    private func configure(cell: ResultsTableViewCell, with resultsInfo: WKRResultsInfo, at index: Int) {
        switch state {
        case .results, .hostResults:
            let player = resultsInfo.raceRankingsPlayer(at: index)
            cell.isShowingCheckmark = readyStates?.isPlayerReady(player) ?? false
            cell.update(for: player, animated: true)
        case .points:
            let sessionResults = resultsInfo.sessionResults(at: index)
            cell.isShowingActivityIndicatorView = false
            cell.isShowingCheckmark = false

            let detailString: String
            if sessionResults.points == 1 {
                detailString = sessionResults.points.description + " PT"
            } else {
                detailString = sessionResults.points.description + " PTS"
            }

            var subtitleString: String
            if sessionResults.ranking == 1 {
                subtitleString = "1st Place"
            } else if  sessionResults.ranking == 2 {
                subtitleString = "2nd Place"
            } else if  sessionResults.ranking == 3 {
                subtitleString = "3rd Place"
            } else {
                subtitleString = "\(sessionResults.ranking)th Place"
            }
            subtitleString += sessionResults.isTied ? " (Tied)" : ""

            cell.update(playerName: sessionResults.profile.name,
                        detail: detailString,
                        subtitle: NSAttributedString(string: subtitleString),
                        animated: false)
        default:
            fatalError("Unexpected state \(state)")
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PlayerMetrics.log(event: .userAction(#function))

        guard let resultsInfo = resultsInfo else {
            return
        }

        let controller = historyViewController ?? HistoryViewController(style: .grouped)
        historyViewController = controller
        controller.player = resultsInfo.raceRankingsPlayer(at: indexPath.row)

        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true, completion: nil)

        PlayerMetrics.log(event: .openedHistory,
                          attributes: ["GameState": state.rawValue.description as Any])
    }

}
