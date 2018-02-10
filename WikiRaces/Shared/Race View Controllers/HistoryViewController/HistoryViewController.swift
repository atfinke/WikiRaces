//
//  HistoryViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

internal class HistoryViewController: StateLogTableViewController {

    private var entries = [WKRHistoryEntry]()
    private var currentPlayerState = WKRPlayerState.connecting

    var player: WKRPlayer? {
        didSet {
            guard let player = player, let history = player.raceHistory else {
                entries = []
                currentPlayerState = .connecting
                tableView.reloadData()
                return
            }

            title = player.name

            guard player == oldValue else {
                currentPlayerState = player.state
                entries = player.raceHistory?.entries ?? []
                tableView.reloadData()
                return
            }

            var rowsToReload = [IndexPath]()
            var rowsToInsert = [IndexPath]()

            if player.state != currentPlayerState {
                currentPlayerState = player.state
                rowsToReload.append(IndexPath(row: history.entries.count - 1))
            }

            for (index, entry) in history.entries.enumerated() {
                if index < entries.count {
                    if entry != entries[index] {
                        entries[index] = entry
                        rowsToReload.append(IndexPath(row: index))

                    }
                } else {
                    entries.insert(entry, at: index)
                    rowsToInsert.append(IndexPath(row: index))
                }
            }

            let adjustedRowsToReload = rowsToReload.filter { indexPath -> Bool in
                return !rowsToInsert.contains(indexPath)
            }

            tableView.beginUpdates()
            tableView.reloadRows(at: adjustedRowsToReload, with: .fade)
            tableView.insertRows(at: rowsToInsert, with: .top)
            tableView.endUpdates()
        }
    }

    @IBAction func doneButtonPressed() {
        PlayerAnalytics.log(event: .userAction(#function))
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = entries[indexPath.row]
        let cellIdentifier = (entry == entries.last && currentPlayerState != .racing) ?
            HistoryTableViewCell.finalReuseIdentifier :
            HistoryTableViewCell.reuseIdentifier

        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier,
                                                       for: indexPath) as? HistoryTableViewCell else {
            fatalError("Unable to create cell")
        }

        let pageTitle = entry.page.title ?? "Unknown Page"
        var attributedText = NSMutableAttributedString(string: pageTitle, attributes: nil)
        if entry.linkHere {
            let detail = " Link Here"
            attributedText = NSMutableAttributedString(string: pageTitle + detail, attributes: nil)

            let range = NSRange(location: pageTitle.count, length: detail.count)
            let attributes: [NSAttributedStringKey: Any] = [
                .foregroundColor: UIColor.lightGray,
                .font: UIFont.systemFont(ofSize: 15)
            ]
            attributedText.addAttributes(attributes, range: range)
        }
        cell.textLabel?.attributedText = attributedText

        cell.isShowingActivityIndicatorView = false
        if let duration = DurationFormatter.string(for: entry.duration) {
            cell.detailTextLabel?.text = duration
        } else if currentPlayerState == .racing {
            cell.isShowingActivityIndicatorView = true
        } else {
            cell.detailTextLabel?.text = currentPlayerState.text
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

}
