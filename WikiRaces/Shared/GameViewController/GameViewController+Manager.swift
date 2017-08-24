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
        }

        switch state {
        case .voting:
            dismissActiveController(completion: {
                self.performSegue(.showVoting)
            })
        case .results, .hostResults, .points:
            if let controller = activeViewController, controller != resultsViewController {
                dismissActiveController(completion: {
                    self.performSegue(.showResults)
                })
            } else if resultsViewController == nil {
                performSegue(.showResults)
            } else {
                resultsViewController?.state = state
            }
        case .race:
            dismissActiveController(completion: nil)
        default: break
        }
    }

}
