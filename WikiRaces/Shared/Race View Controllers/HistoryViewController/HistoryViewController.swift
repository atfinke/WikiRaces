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

import SafariServices

internal class HistoryViewController: StateLogTableViewController, SFSafariViewControllerDelegate {

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

            PlayerMetrics.log(event: .gameState("HVC DEBUG: START"))
            PlayerMetrics.log(event: .gameState("HVC DEBUG: PREV ENTRY COUNT \(entries.count)"))

            title = player.name

            guard player == oldValue else {
                currentPlayerState = player.state
                entries = player.raceHistory?.entries ?? []
                tableView.reloadSections(IndexSet(integer: 0), with: .fade)
                PlayerMetrics.log(event: .gameState("HVC DEBUG: RETURN EARLY"))
                return
            }

            PlayerMetrics.log(event: .gameState("HVC DEBUG: NEW ENTRY COUNT \(entries.count)"))

            var rowsToReload = [IndexPath]()
            var rowsToInsert = [IndexPath]()

            if player.state != currentPlayerState {
                let log = "HVC DEBUG: NEW PLAYER STATE \(player.state.text), OLD: \(currentPlayerState.text)"
                PlayerMetrics.log(event: .gameState(log))

                currentPlayerState = player.state
                rowsToReload.append(IndexPath(row: history.entries.count - 1))
            }

            for (index, entry) in history.entries.enumerated() {
                PlayerMetrics.log(event: .gameState("HVC DEBUG: CHECKING \(index)"))
                if index < entries.count {
                    PlayerMetrics.log(event: .gameState("HVC DEBUG: EXISTING"))
                    if entry != entries[index] {
                        PlayerMetrics.log(event: .gameState("HVC DEBUG: NEEDS UPDATE"))
                        entries[index] = entry
                        rowsToReload.append(IndexPath(row: index))
                    }
                } else {
                    if index < tableView.numberOfRows(inSection: 0) {
                        entries = player.raceHistory?.entries ?? []
                        tableView.reloadSections(IndexSet(integer: 0), with: .fade)
                        PlayerMetrics.log(event: .gameState("HVC DEBUG: ABORT - UNEXPECTED CELL"))
                        PlayerMetrics.log(event: .githubIssue41Hit)
                        return
                    }

                    PlayerMetrics.log(event: .gameState("HVC DEBUG: NEW"))
                    entries.insert(entry, at: index)
                    rowsToInsert.append(IndexPath(row: index))
                }
            }

            PlayerMetrics.log(event: .gameState("HVC DEBUG: PRE ADJUST RELOADS \(rowsToReload)"))

            let adjustedRowsToReload = rowsToReload.filter { indexPath -> Bool in
                return !rowsToInsert.contains(indexPath)
            }

            PlayerMetrics.log(event: .gameState("HVC DEBUG: POST ADJUST RELOADS \(adjustedRowsToReload)"))
            PlayerMetrics.log(event: .gameState("HVC DEBUG: INSERTS \(rowsToInsert)"))

            PlayerMetrics.log(event: .gameState("HVC DEBUG: ENTRIES \(entries.count)"))
            PlayerMetrics.log(event: .gameState("HVC DEBUG: ROWS \(tableView.numberOfRows(inSection: 0))"))

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
            cell.detailLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        } else if currentPlayerState == .racing {
            cell.isShowingActivityIndicatorView = true
        } else {
            cell.detailLabel.text = currentPlayerState.text
            cell.detailLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < entries.count else { return }
        let entry = entries[indexPath.row]

        let controller = SFSafariViewController(url: entry.page.url)
        controller.delegate = self
        controller.preferredControlTintColor = UIColor.wkrTextColor
        if UIDevice.current.userInterfaceIdiom == .pad {
            controller.modalPresentationStyle = .overFullScreen
        }
        present(controller, animated: true, completion: nil)

        PlayerMetrics.log(event: .openedHistorySF)
    }

    // MARK: - SFSafariViewControllerDelegate

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
