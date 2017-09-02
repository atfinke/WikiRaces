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

            destination.didFinish = {
                DispatchQueue.main.async {
                    self.lobbyViewController?.dismiss(animated: true) {
                        self.lobbyViewController = nil
                    }
                }
            }

            destination.startButtonPressed = {
                self.manager.player(.startedGame)
                destination.didFinish?()
            }

            destination.addPlayersButtonPressed = { viewController in
                self.manager.presentNetworkInterface(on: viewController)
            }

            destination.isPlayerHost = isPlayerHost
            destination.isPreMatch = manager.gameState == .preMatch
            destination.displayedPlayers = manager.allPlayers

            self.lobbyViewController = destination
        case .showVoting:
            guard let destination = navigationController.rootViewController as? VotingViewController else {
                fatalError()
            }

            destination.playerVoted = { page in
                self.manager.player(.voted(page))
            }

            destination.voteInfo = manager.voteInfo
            self.votingViewController = destination
        case .showResults:
            guard let destination = navigationController.rootViewController as? ResultsViewController else {
                fatalError()
            }

            destination.readyButtonPressed = {
                self.manager.player(.ready)
            }

            destination.addPlayersButtonPressed = { viewController in
                self.manager.presentNetworkInterface(on: viewController)
            }

            destination.state = manager.gameState
            destination.resultsInfo = manager.hostResultsInfo
            destination.isPlayerHost = isPlayerHost
            self.resultsViewController = destination
        case .showHelp:
            guard let destination = navigationController.rootViewController as? HelpViewController else {
                fatalError()
            }

            destination.linkTapped = {
                self.manager.enqueue(message: "Links disabled in help", duration: 2.0)
            }

            destination.url = manager.finalPageURL
            self.activeViewController = destination
        }
    }

}
