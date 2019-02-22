//
//  GameViewController+Segue.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/30/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

extension GameViewController {

    // MARK: - Types

    enum Segue: String {
        case showVoting
        case showResults
        case showHelp
    }

    // MARK: - Performing Segues

    func performSegue(_ segue: Segue) {
        performSegue(withIdentifier: segue.rawValue, sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController,
            let unwrappedSegueIdentifier = segue.identifier,
            let segueIdentifier = Segue(rawValue: unwrappedSegueIdentifier) else {
                fatalError("Unknown segue \(String(describing: segue.identifier))")
        }

        switch segueIdentifier {
        case .showVoting:
            guard let destination = navigationController.rootViewController as? VotingViewController else {
                fatalError("Destination rootViewController not a VotingViewController")
            }
            prepare(votingViewController: destination)
        case .showResults:
            guard let destination = navigationController.rootViewController as? ResultsViewController else {
                fatalError("Destination rootViewController not a ResultsViewController")
            }
            prepare(resultsViewController: destination)
        case .showHelp:
            guard let destination = navigationController.rootViewController as? HelpViewController else {
                fatalError("Destination rootViewController not a HelpViewController")
            }
            prepare(helpViewController: destination)
        }
    }

    private func prepare(votingViewController: VotingViewController) {
        votingViewController.playerVoted = { [weak self] page in
            self?.gameManager.player(.voted(page))
            PlayerMetrics.log(event: .voted, attributes: ["Page": page.title as Any])

            if let raceType = self?.statRaceType {
                var stat = StatsHelper.Stat.mpcVotes
                switch raceType {
                case .mpc: stat = StatsHelper.Stat.mpcVotes
                case .gameKit: stat = StatsHelper.Stat.gkVotes
                case .solo: stat = StatsHelper.Stat.soloVotes
                default: break
                }
                StatsHelper.shared.increment(stat: stat)
            }
        }

        votingViewController.voteInfo = gameManager.voteInfo

        votingViewController.backupQuit = playerQuit
        votingViewController.quitAlertController = quitAlertController(raceStarted: false)

        self.votingViewController = votingViewController
    }

    private func prepare(resultsViewController: ResultsViewController) {
        resultsViewController.localPlayer = gameManager.localPlayer
        resultsViewController.readyButtonPressed = { [weak self] in
            self?.gameManager.player(.ready)
        }

        resultsViewController.addPlayersViewController = gameManager.hostNetworkInterface()

        resultsViewController.state = gameManager.gameState
        resultsViewController.resultsInfo = gameManager.hostResultsInfo
        resultsViewController.isPlayerHost = networkConfig.isHost

        resultsViewController.backupQuit = playerQuit
        resultsViewController.quitAlertController = quitAlertController(raceStarted: false)

        self.resultsViewController = resultsViewController
    }

    private func prepare(helpViewController: HelpViewController) {
        helpViewController.linkTapped = { [weak self] in
            self?.gameManager.enqueue(message: "Links disabled in help", duration: 2.0, isRaceSpecific: true)
        }

        helpViewController.url = gameManager.finalPageURL
        self.activeViewController = helpViewController

        if let raceType = statRaceType {
            var stat = StatsHelper.Stat.mpcHelp
            switch raceType {
            case .mpc: stat = StatsHelper.Stat.mpcHelp
            case .gameKit: stat = StatsHelper.Stat.gkHelp
            case .solo: stat = StatsHelper.Stat.soloHelp
            default: break
            }
            StatsHelper.shared.increment(stat: stat)
        }
    }

}
