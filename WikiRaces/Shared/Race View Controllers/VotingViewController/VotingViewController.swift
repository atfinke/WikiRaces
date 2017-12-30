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

internal class VotingViewController: CenteredTableViewController {

    // MARK: - Properties

    private var isShowingGuide = false
    private var isShowingVoteCountdown = true

    var playerVoted: ((WKRPage) -> Void)?
    var quitAlertController: UIAlertController?

    var voteInfo: WKRVoteInfo? {
        didSet {
            let selectedPath = tableView.indexPathForSelectedRow
            tableView.reloadData()
            tableView.selectRow(at: selectedPath, animated: false, scrollPosition: .none)
            if isViewLoaded && self.tableView.alpha != 1.0 {
                UIView.animate(withDuration: 0.5, delay: 0.0, animations: {
                    self.tableView.alpha = 1.0
                })
            }
        }
    }

    var voteTimeRemaing = 100 {
        didSet {
            if isShowingVoteCountdown {
                let timeString = "VOTING CLOSES IN " + voteTimeRemaing.description + " S"
                if !isShowingGuide {
                    flashItems(items: [guideLabel, descriptionLabel], duration: 0.75) {
                        self.descriptionLabel.text = timeString
                        self.isShowingGuide = true
                    }
                    tableView.isUserInteractionEnabled = true
                } else if voteTimeRemaing == 0 {
                    descriptionLabel.text = timeString
                    votingEnded()
                } else {
                    descriptionLabel.text = timeString
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

        guideLabel.alpha = 0.0
        guideLabel.text = "TAP ARTICLE TO VOTE"
        descriptionLabel.text = "VOTING STARTS SOON"

        tableView.register(VotingTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if voteInfo != nil {
            UIView.animate(withDuration: 0.5, delay: 0.0, animations: {
                self.tableView.alpha = 1.0
            })
        }
    }

    // MARK: = Actions

    @IBAction func quitButtonPressed(_ sender: Any) {
        PlayerAnalytics.log(event: .userAction(#function))
        guard let alertController = quitAlertController else {
            NotificationCenter.default.post(name: NSNotification.Name("PlayerQuit"), object: nil)
            PlayerAnalytics.log(event: .backupQuit, attributes: ["GameState": WKRGameState.voting.rawValue.description])
            return
        }
        present(alertController, animated: true, completion: nil)
        PlayerAnalytics.log(presentingOf: alertController, on: self)
    }

    // MARK: - Helpers

    func votingEnded() {
        isShowingVoteCountdown = false
        tableView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.5) {
            self.guideLabel.alpha = 0.0
            self.descriptionLabel.alpha = 0.0
        }
    }

    func finalPageSelected(_ page: WKRPage) {
        guard let votingObject = voteInfo, let index = votingObject.index(of: page) else {
            fatalError("Failed to select final page with \(String(describing: voteInfo))")
        }

        UIView.animate(withDuration: 1.5) {
            for i in 0...votingObject.pageCount where i != index {
                let indexPath = IndexPath(row: i)
                self.tableView.cellForRow(at: indexPath)?.alpha = 0.2
            }
        }
    }

}
