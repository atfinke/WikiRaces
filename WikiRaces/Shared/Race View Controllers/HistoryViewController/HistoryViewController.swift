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

internal class HistoryViewController: UITableViewController, SFSafariViewControllerDelegate {

    // MARK: - Properties

    private var isUserScrolling = false
    private var isTableViewAnimating = false

    private var deferredUpdate = false

    private var entries = [WKRHistoryEntry]()
    private var stats: WKRPlayerRaceStats? {
        didSet {
            if stats != oldValue {
                tableView.reloadSections(IndexSet(integer: 1), with: .none)
            }
        }
    }

    var player: WKRPlayer? {
        didSet {
            updateEntries(oldPlayer: oldValue)
        }
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        var frame = CGRect.zero
        frame.size.height = .leastNormalMagnitude
        tableView.tableHeaderView = UIView(frame: frame)

        navigationController?.navigationBar.barStyle = .wkrStyle

        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(HistoryTableViewCell.self,
                           forCellReuseIdentifier: HistoryTableViewCell.reuseIdentifier)
        tableView.register(HistoryTableViewStatsCell.self,
                           forCellReuseIdentifier: HistoryTableViewStatsCell.reuseIdentifier)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop,
                                                            target: self,
                                                            action: #selector(doneButtonPressed))
    }

    // MARK: - Logic

    private func updateEntries(oldPlayer: WKRPlayer?) {
        title = player?.name
        stats = player?.stats

        // New Player
        if let oldPlayer = oldPlayer, oldPlayer != player {
            entries = player?.raceHistory?.entries ?? []
            tableView.reloadData()
            PlayerStat.bugHitCase1.increment()
            return
        }

        guard let player = player, let history = player.raceHistory else {
            entries = []
            tableView.reloadData()
            PlayerStat.bugHitCase2.increment()
            return
        }

        // A different player was updated in the results info object, nothing has changed
        if history.entries == entries && oldPlayer?.state == player.state {
            PlayerStat.bugHitCase3.increment()
            return
        }

        if view.window == nil {
            self.entries = history.entries
            tableView.reloadData()
            PlayerStat.bugHitCase4.increment()
            return
        } else if isUserScrolling || isTableViewAnimating {
            deferredUpdate = true
            PlayerStat.bugHitCase5.increment()
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
            tableView.reloadData()
            PlayerStat.bugHitCase6.increment()
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
            tableView.reloadData()
            PlayerStat.bugHitCase7.increment()
            return
        }

        self.entries = history.entries
        tableView.performBatchUpdates({
            tableView.reloadRows(at: rowsToReload, with: .none)
            tableView.insertRows(at: rowsToInsert, with: .fade)
        }, completion: { _ in
            self.isTableViewAnimating = false
            if self.deferredUpdate {
                self.updateEntries(oldPlayer: nil)
                PlayerStat.bugHitCase8.increment()
            }
        })
    }

    // MARK: - Actions

    @IBAction func doneButtonPressed() {
        PlayerMetrics.log(event: .userAction(#function))
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserScrolling = true
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isUserScrolling = false
        if deferredUpdate {
            updateEntries(oldPlayer: nil)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if player?.stats == nil {
            return 1
        }
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
            cell.detailLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
            cell.isShowingActivityIndicatorView = false
        } else if playerState == .racing {
            cell.detailLabel.text = ""
            cell.isShowingActivityIndicatorView = true
        } else {
            cell.detailLabel.text = playerState.text
            cell.detailLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            cell.isShowingActivityIndicatorView = false
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
