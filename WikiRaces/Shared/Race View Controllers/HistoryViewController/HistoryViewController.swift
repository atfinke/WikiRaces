//
//  HistoryViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit

internal class HistoryViewController: StateLogTableViewController {

    // MARK: - Properties

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
                tableView.reloadSections(IndexSet(integer: 0), with: .fade)
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

            tableView.performBatchUpdates({
                tableView.reloadRows(at: adjustedRowsToReload, with: .fade)
                tableView.insertRows(at: rowsToInsert, with: .fade)
            }, completion: nil)
        }
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.barStyle = .wkrStyle

        tableView.backgroundColor = UIColor.wkrBackgroundColor
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(HistoryTableViewCell.self,
                           forCellReuseIdentifier: HistoryTableViewCell.reuseIdentifier)
    }

    // MARK: - Actions

    @IBAction func doneButtonPressed() {
        PlayerMetrics.log(event: .userAction(#function))
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HistoryTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? HistoryTableViewCell else {
            fatalError("Unable to create cell")
        }

        let entry = entries[indexPath.row]
        cell.pageLabel.text = entry.page.title ?? "Unknown Page"
        cell.isLinkHere = entry.linkHere

        cell.isShowingActivityIndicatorView = false
        if let duration = DurationFormatter.string(for: entry.duration) {
            cell.detailLabel.text = duration
            cell.detailLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        } else if currentPlayerState == .racing {
            cell.isShowingActivityIndicatorView = true
        } else {
            cell.detailLabel.text = currentPlayerState.text
            cell.detailLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        }

        return cell
    }

}
