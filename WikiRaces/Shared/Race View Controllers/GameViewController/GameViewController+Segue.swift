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
        case showPlayers
        case showVoting
        case showResults
        case showHelp
    }

    // MARK: - Performing Segues

    func performSegue(_ segue: Segue) {
        performSegue(withIdentifier: segue.rawValue, sender: nil)
    }

    //swiftlint:disable:next function_body_length
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController,
            let unwrappedSegueIdentifier = segue.identifier,
            let segueIdentifier = Segue(rawValue: unwrappedSegueIdentifier) else {
                fatalError("Unknown segue \(String(describing: segue.identifier))")
        }

        switch segueIdentifier {
        case .showPlayers:
            guard let destination = navigationController.rootViewController as? LobbyViewController else {
                fatalError()
            }

            destination.startButtonPressed = { [weak self] in
                self?.manager.player(.startedGame)
            }

            destination.addPlayersButtonPressed = { [weak self] viewController in
                if let controller = self?.manager.hostNetworkInterface() {
                    viewController.present(controller, animated: true, completion: nil)
                }
            }

            destination.isPlayerHost = isPlayerHost
            destination.quitAlertController = quitAlertController(raceStarted: false)

            self.lobbyViewController = destination
        case .showVoting:
            guard let destination = navigationController.rootViewController as? VotingViewController else {
                fatalError()
            }

            destination.playerVoted = { [weak self] page in 
                self?.manager.player(.voted(page))
            }

            destination.voteInfo = manager.voteInfo
            destination.quitAlertController = quitAlertController(raceStarted: false)

            self.votingViewController = destination
        case .showResults:
            guard let destination = navigationController.rootViewController as? ResultsViewController else {
                fatalError()
            }

            destination.readyButtonPressed = { [weak self] in
                self?.manager.player(.ready)
            }

            destination.addPlayersButtonPressed = { [weak self] viewController in
                if let controller = self?.manager.hostNetworkInterface() {
                    viewController.present(controller, animated: true, completion: nil)
                }
            }

            destination.state = manager.gameState
            destination.resultsInfo = manager.hostResultsInfo
            destination.isPlayerHost = isPlayerHost
            destination.quitAlertController = quitAlertController(raceStarted: false)

            self.resultsViewController = destination
        case .showHelp:
            guard let destination = navigationController.rootViewController as? HelpViewController else {
                fatalError()
            }

            destination.linkTapped = { [weak self] in
                self?.manager.enqueue(message: "Links disabled in help", duration: 2.0)
            }

            destination.url = manager.finalPageURL
            self.activeViewController = destination
        }
    }

}
