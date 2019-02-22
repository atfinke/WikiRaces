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

    var player: WKRPlayer? {
        didSet {
            updateEntries()
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

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop,
                                                            target: self,
                                                            action: #selector(doneButtonPressed))
    }

    // MARK: - Logic

    private func updateEntries() {
        guard let player = player, let history = player.raceHistory else {
            entries = []
            tableView.reloadData()
            title = nil
            return
        }
        title = player.name

        if view.window == nil {
            self.entries = history.entries
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
        let startIndex = entries.count
        let endIndex = startIndex + newEntryCount
        for index in startIndex..<endIndex {
            rowsToInsert.append(IndexPath(row: index))
        }

        self.entries = history.entries
        tableView.performBatchUpdates({
            tableView.reloadRows(at: rowsToReload, with: .fade)
            tableView.insertRows(at: rowsToInsert, with: .fade)
        }, completion: { _ in
            self.isTableViewAnimating = false
            if self.deferredUpdate {
                self.updateEntries()
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
            updateEntries()
        }
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

        let playerState = player?.state ?? .connecting

        let entry = entries[indexPath.row]
        cell.pageLabel.text = entry.page.title ?? "Unknown Page"
        cell.isLinkHere = entry.linkHere

        cell.isShowingActivityIndicatorView = false
        if let duration = DurationFormatter.string(for: entry.duration) {
            cell.detailLabel.text = duration
            cell.detailLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        } else if playerState == .racing {
            cell.detailLabel.text = ""
            cell.isShowingActivityIndicatorView = true
        } else {
            cell.detailLabel.text = playerState.text
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
