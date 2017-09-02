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
        let playerCount = resultsInfo?.playerCount ?? 0
        return (isPlayerHost && state == .hostResults) ? playerCount + 1 : playerCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == (resultsInfo?.playerCount ?? 0) {
            //swiftlint:disable:next line_length
            guard let cell = tableView.dequeueReusableCell(withIdentifier: footerCellReuseIdentifier, for: indexPath) as? FooterButtonTableViewCell else {
                fatalError()
            }
            cell.button.title = "Invite Players"
            cell.button.addTarget(self, action: #selector(footerButtonPressed), for: .touchUpInside)
            cell.thinLine.isHidden = true
            return cell
        } else {
            //swiftlint:disable:next line_length
            guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? ResultsTableViewCell,
                let resultsInfo = resultsInfo else {
                    fatalError()
            }
            configure(cell: cell, with: resultsInfo, at: indexPath.row)
            return cell
        }
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
                if player.raceHistory?.entries.last?.linkHere ?? false {
                    let detail = " Link On Page"
                    let attributedText = NSMutableAttributedString(string: player.name + detail, attributes: nil)

                    let range = NSRange(location: player.name.characters.count, length: detail.characters.count)
                    let attributes: [NSAttributedStringKey: Any] = [
                        .foregroundColor: UIColor.lightGray,
                        .font: UIFont.systemFont(ofSize: 15)
                    ]
                    attributedText.addAttributes(attributes, range: range)
                    cell.playerLabel.attributedText = attributedText
                }
            } else if player.state == .foundPage {
                cell.detailLabel.text = DurationFormatter.string(for: player.raceHistory?.duration)
            } else {
                cell.detailLabel.text = player.state.text
            }
        case .points:
            let points = resultsInfo.pointsInfo(at: index)
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
        _debugLog(indexPath)
        guard let resultsInfo = resultsInfo, indexPath.row != resultsInfo.playerCount else {
            return
        }
        let player = resultsInfo.player(at: indexPath.row)
        performSegue(withIdentifier: "showHistory", sender: player)
    }

}
