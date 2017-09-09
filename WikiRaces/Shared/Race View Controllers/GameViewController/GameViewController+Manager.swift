//
//  GameViewController+Manager.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import Foundation
import WKRKit

extension GameViewController {

    // MARK: - WKRManager

    //swiftlint:disable line_length function_body_length
    func setupManager() {
        #if MULTIWINDOWDEBUG
            manager = WKRManager(windowName: windowName, isPlayerHost: isPlayerHost, stateUpdate: { state, _ in
                self.transition(to: state)
            }, pointsUpdate: { playerPoints in
                StatsHelper.shared.completedRace(points: playerPoints)
            }, playersUpdate: { localPlayer, players in
                self.lobbyViewController?.updatedConnectedPlayers(players: players)
                // remove counter increment during page load
                self.webView.text = localPlayer.raceHistory?.entries.filter({ $0.duration != nil }).count.description
            })
        #else
            manager = WKRManager(serviceType: serviceType, session: session, isPlayerHost: isPlayerHost, stateUpdate: {  [weak self] state, error in
                if let error = error {
                    self?.errorOccurred(error)
                } else {
                    self?.transition(to: state)
                }
            }, pointsUpdate: { playerPoints in
                StatsHelper.shared.completedRace(points: playerPoints)
            }, playersUpdate: {  [weak self] localPlayer, players in
                self?.lobbyViewController?.updatedConnectedPlayers(players: players)
                // remove counter increment during page load
                self?.webView.text = localPlayer.raceHistory?.entries.filter({ $0.duration != nil }).count.description
            })
        #endif

        manager.voting(timeUpdate: { [weak self] time in
            self?.votingViewController?.voteTimeRemaing = time
        }, infoUpdate: { [weak self] voteInfo in
            self?.votingViewController?.voteInfo = voteInfo
        }, finalPageUpdate: { [weak self] page in
            self?.finalPage = page
            self?.votingViewController?.finalPageSelected(page)
            UIView.animate(withDuration: 0.5, delay: 0.75, animations: {
                self?.webView.alpha = 1.0
            }, completion: nil)
        })

        manager.results(showReady: { [weak self] showReady in
            self?.resultsViewController?.showReadyUpButton(showReady)
        }, timeUpdate: { [weak self] time in
            self?.resultsViewController?.timeRemaining = time
        }, infoUpdate: { [weak self] resultsInfo in
            if self?.resultsViewController?.state != .hostResults {
                self?.resultsViewController?.resultsInfo = resultsInfo
            }
        }, hostInfoUpdate: { [weak self] resultsInfo in
            self?.resultsViewController?.resultsInfo = resultsInfo
        }, readyStatesUpdate: { [weak self] readyStates in
            self?.resultsViewController?.readyStates = readyStates
        })
    }
    //swiftlint:enable line_length

    private func errorOccurred(_ error: WKRFatalError) {
        let alertController = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
        let quitAction = UIAlertAction(title: "Menu", style: .default) { _ in
            NotificationCenter.default.post(name: NSNotification.Name("PlayerQuit"), object: nil)
        }
        alertController.addAction(quitAction)

        DispatchQueue.main.async {
            self.dismissActiveController(completion: {
                self.present(alertController, animated: true, completion: nil)
                self.activeViewController = alertController
            })
        }
    }

    private func resetActiveControllers() {
        alertController = nil
        lobbyViewController = nil
        votingViewController = nil
        resultsViewController = nil
    }

    private func dismissActiveController(completion: (() -> Void)?) {
        if let activeViewController = activeViewController, activeViewController.view.window != nil {
            let controller: UIViewController?
            if activeViewController.presentingViewController == self {
                controller = activeViewController
            } else {
                controller = activeViewController.presentingViewController
            }
            controller?.dismiss(animated: true, completion: {
                self.resetActiveControllers()
                completion?()
                return
            })
        } else {
            resetActiveControllers()
            completion?()
        }
    }

    private func transition(to state: WKRGameState) {
        guard state != gameState else { return }
        gameState = state

        switch state {
        case .voting:
            self.title = ""
            dismissActiveController(completion: {
                self.performSegue(.showVoting)
            })
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = nil
        case .results, .hostResults, .points:
            if activeViewController != resultsViewController || resultsViewController == nil {
                dismissActiveController(completion: {
                    self.performSegue(.showResults)
                    UIView.animate(withDuration: 0.5, delay: 2.5, options: .beginFromCurrentState, animations: {
                        self.webView.alpha = 0.0
                    }, completion: nil)
                })
            } else {
                resultsViewController?.state = state
            }
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = nil
        case .race:
            dismissActiveController(completion: nil)
            navigationItem.leftBarButtonItem = flagBarButtonItem
            navigationItem.rightBarButtonItem = quitBarButtonItem
        default: break
        }
    }

}
