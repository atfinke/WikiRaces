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

    //swiftlint:disable line_length
    func setupManager() {
        #if MULTIWINDOWDEBUG
            manager = WKRManager(windowName: windowName, isPlayerHost: isPlayerHost, stateUpdate: { state in
                self.transition(to: state)
            }, playersUpdate: { players in
                self.lobbyViewController?.updatedConnectedPlayers(players: players)
            })
        #else
            manager = WKRManager(serviceType: serviceType, session: session, isPlayerHost: isPlayerHost, stateUpdate: { state in
                self.transition(to: state)
            }, playersUpdate: { players in
                self.lobbyViewController?.updatedConnectedPlayers(players: players)
            })
        #endif

        manager.voting(timeUpdate: { time in
            self.votingViewController?.voteTimeRemaing = time
        }, infoUpdate: { voteInfo in
            self.votingViewController?.voteInfo = voteInfo
        }, finalPageUpdate: { page in
            self.finalPage = page
            self.votingViewController?.finalPageSelected(page)
            UIView.animate(withDuration: 0.5, delay: 0.75, animations: {
                self.webView.alpha = 1.0
            }, completion: nil)
        })

        manager.results(showReady: { showReady in
            self.resultsViewController?.showReadyUpButton(showReady)
        }, timeUpdate: { time in
            self.resultsViewController?.timeRemaining = time
        }, infoUpdate: { resultsInfo in
            if self.resultsViewController?.state != .hostResults {
                self.resultsViewController?.resultsInfo = resultsInfo
            }
        }, hostInfoUpdate: { resultsInfo in
            self.resultsViewController?.resultsInfo = resultsInfo
        }, readyStatesUpdate: { readyStates in
            self.resultsViewController?.readyStates = readyStates
        })
    }
    //swiftlint:enable line_length

    //swiftlint:disable:next function_body_length
    private func transition(to state: WKRGameState) {
        guard state != gameState else { return }
        gameState = state

        func resetActiveControllers() {
            alertController = nil
            lobbyViewController = nil
            votingViewController = nil
            resultsViewController = nil
        }

        func dismissActiveController(completion: (() -> Void)?) {
            if let activeViewController = activeViewController, activeViewController.view.window != nil {
                let controller: UIViewController?
                if activeViewController.presentingViewController == self {
                    controller = activeViewController
                } else {
                    controller = activeViewController.presentingViewController
                }
                controller?.dismiss(animated: true, completion: {
                    resetActiveControllers()
                    completion?()
                    return
                })
            } else {
                resetActiveControllers()
                completion?()
            }
        }

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
