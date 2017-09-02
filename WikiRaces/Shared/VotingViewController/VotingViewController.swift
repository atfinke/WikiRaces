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
    @IBAction func quitBarButtonItemPressed(_ sender: Any) {
    }
    
    var isShowingVoteCountdown = true
    var quitButtonPressed: ((UIViewController) -> Void)?
    var playerVoted: ((WKRPage) -> Void)?

    var voteInfo: WKRVoteInfo? {
        didSet {
            if self.tableView.alpha != 1.0 {
                UIView.animate(withDuration: 0.5, delay: 0.0, animations: {
                    self.tableView.alpha = 1.0
                })
            }
            let selectedPath = tableView.indexPathForSelectedRow
            tableView.reloadData()
            tableView.selectRow(at: selectedPath, animated: false, scrollPosition: .none)
        }
    }
    var voteTimeRemaing = 100 {
        didSet {
            if isShowingVoteCountdown {
                if voteTimeRemaing == 0 {
                    votingEnded()
                } else {
                    tableView.isUserInteractionEnabled = true
                    descriptionLabel.text = "VOTING CLOSES IN " + voteTimeRemaing.description + " S"
                }
            } else {
                if descriptionLabel.alpha != 1.0 {
                    UIView.animate(withDuration: 0.5, delay: 0.5, animations: {
                        self.descriptionLabel.alpha = 1.0
                    })
                }
                descriptionLabel.text = "RACE STARTS IN " + voteTimeRemaing.description + " S"
            }
        }
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        _debugLog(nil)

        tableView.alpha = 0.0
        registerTableView(for: self)

        title = "VOTING"
        descriptionLabel.text = "VOTING STARTS SOON"
        descriptionLabel.textColor = UIColor.wkrTextColor

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
