//
//  ResultsViewController+TableView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit
//
//extension ResultsViewController: UITableViewDataSource, UITableViewDelegate {
//
//    // MARK: - UITableViewDataSource
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return resultsInfo?.playerCount ?? 0
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? ResultsTableViewCell,
//            let resultsInfo = resultsInfo else {
//                fatalError("Unable to create cell")
//        }
//        configure(cell: cell, with: resultsInfo, at: indexPath.row)
//        return cell
//    }
//
//    private func configure(cell: ResultsTableViewCell, with resultsInfo: WKRResultsInfo, at index: Int) {
//        switch state {
//        case .results, .hostResults:
//            let player = resultsInfo.raceRankingsPlayer(at: index)
//            cell.isShowingCheckmark = readyStates?.isPlayerReady(player) ?? false
//            cell.updateResults(for: player, animated: true)
//        case .points:
//            let sessionResults = resultsInfo.sessionResults(at: index)
//            cell.updateStandings(for: sessionResults)
//        default:
//            // Unexpected state
//            cell.isShowingActivityIndicatorView = false
//            cell.isShowingCheckmark = false
//        }
//    }
//
//    // MARK: - UITableViewDelegate
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        PlayerAnonymousMetrics.log(event: .userAction(#function))
//
//        guard let resultsInfo = resultsInfo else {
//            return
//        }
//
//        let controller = HistoryViewController(style: .grouped)
//        historyViewController = controller
//        controller.player = resultsInfo.raceRankingsPlayer(at: indexPath.row)
//
//        let navController = WKRUINavigationController(rootViewController: controller)
//        navController.modalPresentationStyle = .formSheet
//        present(navController, animated: true, completion: nil)
//
//        PlayerAnonymousMetrics.log(event: .openedHistory,
//                          attributes: ["GameState": state.rawValue.description as Any])
//    }
//
//}
