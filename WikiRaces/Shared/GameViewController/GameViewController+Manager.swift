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

    func setupManager() {
        #if MULTIWINDOWDEBUG
            manager = WKRManager(_playerName: _playerName, isHost: isPlayerHost, stateUpdate: { state in
                self.transition(to: state)
            }, playersUpdate: { players in
                self.playersViewController?.updatedConnectedPlayers(players: players)
                self.resultsViewController?.players = players
            })
        #else
            manager = WKRManager(session: session, isHost: isPlayerHost, stateUpdate: { state in
                self.transition(to: state)
            }, playersUpdate: { players in
                self.playersViewController?.updatedConnectedPlayers(players: players)
                self.resultsViewController?.players = players
            })
        #endif

        manager.voting(timeUpdate: { time in
            self.votingViewController?.updateVoteTimeRemaining(to: time)
        }, infoUpdate: { voteInfo in
            self.votingViewController?.updateVotingInfo(to: voteInfo)
        }, finalPageUpdate: { page in
            self.title = page.title?.uppercased()
            self.votingViewController?.finalPageSelected(page)
            UIView.animate(withDuration: 0.5, delay: 0.75, options: .beginFromCurrentState, animations: {
                self.webView.alpha = 1.0
            }, completion: nil)
        })

        manager.results(timeUpdate: { time in
            self.resultsViewController?.timeRemaining = time
        }, infoUpdate: { resultsInfo in
            if self.resultsViewController?.state != .hostResults {
                self.resultsViewController?.resultsInfo = resultsInfo
            } else {
                _debugLog("Not updating results")
            }
        }, hostInfoUpdate: { resultsInfo in
            self.resultsViewController?.resultsInfo = resultsInfo
        }, readyStatesUpdate: { readyStates in
            self.resultsViewController?.readyStates = readyStates
        })
    }

    private func transition(to state: WKRGameState) {
        _debugLog(state)

        func dismissActiveController(completion: (() -> Void)?) {
            if let viewController = activeViewController {
                var controllerToDismiss = viewController
                if let presentingViewController = viewController.presentingViewController {
                    controllerToDismiss = presentingViewController
                }

                controllerToDismiss.dismiss(animated: true, completion: {
                    _debugLog(nil)
                    self.activeViewController = nil
                    completion?()
                    return
                })
            } else {
                completion?()
            }
            votingViewController = nil
            playersViewController = nil
            resultsViewController = nil
        }

        switch state {
        case .voting:
            self.title = "VOTING"
            dismissActiveController(completion: {
                self.performSegue(.showVoting)
            })
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = nil
        case .results, .hostResults, .points:
            if let controller = activeViewController, controller != resultsViewController {
                dismissActiveController(completion: {
                    self.performSegue(.showResults)
                    UIView.animate(withDuration: 0.5, delay: 2.5, options: .beginFromCurrentState, animations: {
                        self.webView.alpha = 0.0
                    }, completion: nil)
                })
            } else if resultsViewController == nil {
                performSegue(.showResults)
                UIView.animate(withDuration: 0.5, delay: 2.5, options: .beginFromCurrentState, animations: {
                    self.webView.alpha = 0.0
                }, completion: nil)
            } else {
                resultsViewController?.state = state
            }
            navigationController?.setNavigationBarHidden(false, animated: true)
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
