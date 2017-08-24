//
//  HistoryViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

class HistoryViewController: UITableViewController {

    private var entries = [WKRHistoryEntry]()
    private var playerState = WKRPlayerState.connecting

    var player: WKRPlayer? {
        didSet {
            guard let player = player, let history = player.raceHistory else {
                entries = []
                playerState = .connecting
                tableView.reloadData()
                return
            }

            title = player.name

            tableView.beginUpdates()
            if player.state != playerState {
                let lastIndex = IndexPath(row: history.entries.count - 1, section: 0)
                tableView.reloadRows(at: [lastIndex], with: .automatic)
            }
            playerState = player.state

            for (index, entry) in history.entries.enumerated() {
                if index < entries.count {
                    if entry != entries[index] {
                        entries.remove(at: index)
                        entries.insert(entry, at: index)
                        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                } else {
                    entries.insert(entry, at: index)
                    tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
            }
            tableView.endUpdates()
        }
    }


    @IBAction func doneButtonPressed() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HistoryTableViewCell.reuseIdentifier, for: indexPath) as? HistoryTableViewCell else {
            fatalError()
        }
        let entry = entries[indexPath.row]

        let pageTitle = entry.page.title ?? "Unknown Page"
        var attributedText = NSMutableAttributedString(string: pageTitle, attributes: nil)
        if entry.linkHere {
            let detail = " Link Here"
            attributedText = NSMutableAttributedString(string: pageTitle + detail, attributes: nil)

            let range = NSRange(location: pageTitle.characters.count, length: detail.characters.count)
            let attributes: [NSAttributedStringKey: Any] = [
                .foregroundColor: UIColor.lightGray,
                .font : UIFont.systemFont(ofSize: 15)
            ]
            attributedText.addAttributes(attributes, range: range)
        }
        cell.textLabel?.attributedText = attributedText

        cell.isShowingActivityIndicatorView = false
        if let duration = DurationFormatter.string(for: entry.duration) {
            cell.detailTextLabel?.text = duration
        } else if playerState == .racing {
            cell.isShowingActivityIndicatorView = true
        } else {
            cell.detailTextLabel?.text = playerState.text
        }

        return cell
    }

}

