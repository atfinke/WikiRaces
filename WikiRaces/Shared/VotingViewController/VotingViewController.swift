//
//  VotingViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit

class VotingViewController: CenteredTableViewController {

    // MARK: - Properties

    var isShowingVoteCountdown = true

    var voteInfo: WKRVoteInfo?
    var playerVoted: ((WKRPage) -> Void)?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        _debugLog(nil)

        registerTableView(for: self)

        title = "VOTING"
        descriptionLabel.text = "VOTING STARTS SOON"
        descriptionLabel.textColor = UIColor.wkrTextColor

        isOverlayButtonHidden = true
        tableView.register(VotingTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    }

    // MARK: - Helpers

    func votingEnded() {
        _debugLog(nil)
        isShowingVoteCountdown = false
        descriptionLabel.text = "VOTING CLOSES IN 0 S"
        tableView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.5) {
            self.descriptionLabel.alpha = 0.0
        }
    }

    func updateVotingInfo(to newVoteInfo: WKRVoteInfo) {
        _debugLog(newVoteInfo)
        self.voteInfo = newVoteInfo

        let selectedPath = tableView.indexPathForSelectedRow
        tableView.reloadData()
        tableView.selectRow(at: selectedPath, animated: false, scrollPosition: .none)
    }

    func updateVoteTimeRemaining(to time: Int) {
        _debugLog(time)

        if isShowingVoteCountdown {
            if time == 0 {
                votingEnded()
            } else {
                tableView.isUserInteractionEnabled = true
                descriptionLabel.text = "VOTING CLOSES IN " + time.description + " S"
            }
        } else {
            if descriptionLabel.alpha != 1.0 {
                UIView.animate(withDuration: 0.5) {
                    self.descriptionLabel.alpha = 1.0
                }
            }
            descriptionLabel.text = "RACE STARTS IN " + time.description + " S"
        }
    }

    func finalPageSelected(_ page: WKRPage) {
        _debugLog(page)

        guard let votingObject = voteInfo, let index = votingObject.index(of: page) else { fatalError() }

        UIView.animate(withDuration: 1.5) {
            for i in 0...votingObject.pageCount where i != index {
                let indexPath = IndexPath(row: i)
                self.tableView.cellForRow(at: indexPath)?.alpha = 0.05
            }
        }
    }

}
