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

final internal class HistoryViewController: UITableViewController, SFSafariViewControllerDelegate {

    // MARK: - Properties -

    private var isUserScrolling = false
    private var isTableViewAnimating = false

    private var deferredUpdate = false

    private var entries = [WKRHistoryEntry]()
    private var stats: WKRPlayerRaceStats?

    private var safariController: SFSafariViewController?

    var player: WKRPlayer? {
        didSet {
            updateEntries(oldPlayer: oldValue)
        }
    }

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        var frame = CGRect.zero
        frame.size.height = .leastNormalMagnitude
        tableView.tableHeaderView = UIView(frame: frame)

        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(HistoryTableViewCell.self,
                           forCellReuseIdentifier: HistoryTableViewCell.reuseIdentifier)
        tableView.register(HistoryTableViewStatsCell.self,
                           forCellReuseIdentifier: HistoryTableViewStatsCell.reuseIdentifier)

        navigationItem.rightBarButtonItem = WKRUIBarButtonItem(
            systemName: "xmark",
            target: self,
            action: #selector(doneButtonPressed))
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        safariController?.preferredControlTintColor = .wkrTextColor(for: traitCollection)
    }

    // MARK: - Logic -

    // Update the table, with the goal of only updating the changed entries
    // 1. Make sure the player is the same as the currently displayed one (else update the whole table)
    // 2. Make sure the player and their history not nil (else ...)
    // 3. Make sure something has changed
    // 4. Make sure the controller is visable (else ...)
    // 5. Make sure we aren't animating and the user isn't scrolling, otherwise the update will look poor (else ...)
    // 6. Make sure that the new player object has more history entries (else ...)
    // 7. Make sure we have the correct amount of new cells to insert (else ...)
    // 8. Check if we have the same number of stats, if yes, don't use a table animation to update them
    private func updateEntries(oldPlayer: WKRPlayer?) {
        title = player?.name

        // New Player
        if let oldPlayer = oldPlayer, oldPlayer != player {
            entries = player?.raceHistory?.entries ?? []
            stats = player?.stats
            tableView.reloadData()
            return
        }

        guard let player = player, let history = player.raceHistory else {
            entries = []
            stats = nil
            tableView.reloadData()
            return
        }

        // A different player was updated in the results info object, nothing has changed
        if history.entries == entries && oldPlayer?.state == player.state {
            return
        }

        if view.window == nil {
            self.entries = history.entries
            stats = player.stats
            tableView.reloadData()
            return
        } else if isUserScrolling || isTableViewAnimating {
            deferredUpdate = true
            return
        }
        isTableViewAnimating = true
        deferredUpdate = false

        var rowsToReload = [IndexPath]()
        var rowsToInsert = [IndexPath]()

        if !entries.isEmpty {
            rowsToReload.append(IndexPath(row: entries.count - 1))
        }

        let newEntryCount = history.entries.count - entries.count
        // got an older history object, reset table
        if newEntryCount < 0 {
            self.entries = history.entries
            stats = player.stats
            tableView.reloadData()
            return
        }

        let startIndex = entries.count
        let endIndex = startIndex + newEntryCount
        for index in startIndex..<endIndex {
            rowsToInsert.append(IndexPath(row: index))
        }

        // make sure the new history count = old + cell insert count
        guard history.entries.count == entries.count + rowsToInsert.count else {
            self.entries = history.entries
            stats = player.stats
            tableView.reloadData()
            return
        }

        self.entries = history.entries

        let oldStats = stats
        stats = player.stats
        let shouldUpdateStatsInfo = oldStats != stats
        let shouldUpdateStatsCount = oldStats?.raw.count != stats?.raw.count

        // Don't do a table animation if just updating the values
        if let stats = stats, shouldUpdateStatsInfo && !shouldUpdateStatsCount {
            for (index, stat) in stats.raw.enumerated() {
                let indexPath = IndexPath(row: index, section: 1)
                let cell = tableView.cellForRow(at: indexPath) as? HistoryTableViewStatsCell
                cell?.stat = stat
            }
        }


        tableView.performBatchUpdates({
            tableView.reloadRows(at: rowsToReload, with: .none)
            tableView.insertRows(at: rowsToInsert, with: .fade)

            // Update with table animation if the number of stats has changed
            if shouldUpdateStatsCount {
                tableView.reloadSections(IndexSet(integer: 1), with: .none)
            }

        }, completion: { _ in
            self.isTableViewAnimating = false
            if self.deferredUpdate {
                self.updateEntries(oldPlayer: nil)
            }
        })
    }

    // MARK: - Actions -

    @IBAction func doneButtonPressed() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - UIScrollViewDelegate -

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserScrolling = true
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isUserScrolling = false
        if deferredUpdate {
            updateEntries(oldPlayer: nil)
        }
    }

    // MARK: - Table view data source -

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 0 ? "Tap an article to view on Wikipedia" : nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? entries.count : (stats?.raw.count ?? 0)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? super.tableView(tableView, heightForRowAt: indexPath) : 40
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HistoryTableViewStatsCell.reuseIdentifier,
                                                           for: indexPath) as? HistoryTableViewStatsCell else {
                                                            fatalError("Unable to create cell")
            }

            cell.stat = stats?.raw[indexPath.row]
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HistoryTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? HistoryTableViewCell else {
                                                        fatalError("Unable to create cell")
        }

        let playerState = player?.state ?? .connecting

        let entry = entries[indexPath.row]
        cell.pageLabel.text = entry.page.title ?? "Unknown Page"
        cell.isLinkHere = entry.linkHere

        if let duration = WKRDurationFormatter.string(for: entry.duration) {
            cell.detailLabel.text = duration
            cell.detailLabel.font = UIFont.systemRoundedFont(ofSize: 18, weight: .regular)
            cell.isShowingActivityIndicatorView = false
        } else if playerState == .racing {
            cell.detailLabel.text = ""
            cell.isShowingActivityIndicatorView = true
        } else {
            cell.detailLabel.text = playerState.text
            cell.detailLabel.font = UIFont.systemRoundedFont(ofSize: 18, weight: .medium)
            cell.isShowingActivityIndicatorView = false
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < entries.count else { return }
        let entry = entries[indexPath.row]

        let controller = SFSafariViewController(url: entry.page.url)
        controller.delegate = self

        controller.preferredControlTintColor = .wkrTextColor(for: traitCollection)
        if UIDevice.current.userInterfaceIdiom == .pad {
            controller.modalPresentationStyle = .overFullScreen
        }
        present(controller, animated: true, completion: nil)
        safariController = controller

        PlayerAnonymousMetrics.log(event: .openedHistorySF)
    }

    // MARK: - SFSafariViewControllerDelegate -

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        safariController = nil
    }

}
