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
    var playerVoted: ((WKRPage) -> Void)?
    var quitAlertController: UIAlertController?

    var voteInfo: WKRVoteInfo? {
        didSet {
            let selectedPath = tableView.indexPathForSelectedRow
            tableView.reloadData()
            tableView.selectRow(at: selectedPath, animated: false, scrollPosition: .none)
            if self.tableView.alpha != 1.0 {
                UIView.animate(withDuration: 0.5, delay: 0.0, animations: {
                    self.tableView.alpha = 1.0
                })
            }
        }
    }

    var voteTimeRemaing = 100 {
        didSet {
            if isShowingVoteCountdown {
                descriptionLabel.text = "VOTING CLOSES IN " + voteTimeRemaing.description + " S"
                if voteTimeRemaing == 0 {
                    votingEnded()
                } else {
                    tableView.isUserInteractionEnabled = true
                }
            } else {
                descriptionLabel.text = "RACE STARTS IN " + voteTimeRemaing.description + " S"
                if descriptionLabel.alpha != 1.0 {
                    UIView.animate(withDuration: 0.5, delay: 0.5, animations: {
                        self.descriptionLabel.alpha = 1.0
                    })
                }
            }
        }
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.alpha = 0.0
        registerTableView(for: self)

        title = "VOTING"
        descriptionLabel.text = "VOTING STARTS SOON"
        descriptionLabel.textColor = UIColor.wkrTextColor

        tableView.register(VotingTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    }

    // MARK: = Actions

    @IBAction func quitButtonPressed(_ sender: Any) {
        guard let alertController = quitAlertController else { fatalError() }
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Helpers

    func votingEnded() {
        isShowingVoteCountdown = false
        tableView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.5) {
            self.descriptionLabel.alpha = 0.0
        }
    }

    func finalPageSelected(_ page: WKRPage) {
        guard let votingObject = voteInfo, let index = votingObject.index(of: page) else {
            fatalError()
        }

        UIView.animate(withDuration: 1.5) {
            for i in 0...votingObject.pageCount where i != index {
                let indexPath = IndexPath(row: i)
                self.tableView.cellForRow(at: indexPath)?.alpha = 0.2
            }
        }
    }

}
