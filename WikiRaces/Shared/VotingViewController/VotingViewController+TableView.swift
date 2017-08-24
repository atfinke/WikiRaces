//
//  VotingViewController+TableView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//
import UIKit

extension VotingViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voteInfo?.pageCount ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //swiftlint:disable:next line_length
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? VotingTableViewCell else {
            fatalError()
        }
        cell.vote = voteInfo?.page(for: indexPath.row)
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        wikiDebugLog(indexPath)
        guard let lastIndexPath = tableView.indexPathForSelectedRow else {
            return indexPath
        }
        if lastIndexPath == indexPath {
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        wikiDebugLog(indexPath)
        if let vote = voteInfo?.page(for: indexPath.row) {
            wikiDebugLog(vote)
            playerVoted?(vote.page)
        }
    }

}
