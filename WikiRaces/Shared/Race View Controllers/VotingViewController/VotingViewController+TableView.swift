//
//  VotingViewController+TableView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//
import UIKit

extension VotingViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: - UITableViewDataSource -

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voteInfo?.pageCount ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? VotingTableViewCell else {
            fatalError("Failed to create cell")
        }
        cell.vote = voteInfo?.page(for: indexPath.row)
        return cell
    }

    // MARK: - UITableViewDelegate -

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let lastIndexPath = tableView.indexPathForSelectedRow else {
            UISelectionFeedbackGenerator().selectionChanged()
            return indexPath
        }
        if lastIndexPath == indexPath {
            return nil
        }

        UISelectionFeedbackGenerator().selectionChanged()

        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        guard let vote = voteInfo?.page(for: indexPath.row) else {
            return
        }

        listenerUpdate?(.voted(vote.page))
    }

}
