//
//  GameViewController+Manager.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import WKRKit

extension GameViewController {

    // MARK: - WKRGameManager

    func setupGameManager() {
        gameManager = WKRGameManager(networkConfig: networkConfig, stateUpdate: { [weak self] state, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorOccurred(error)
                }
            } else {
                PlayerMetrics.log(event: .gameState("Transition: \(state)."))
                self?.transition(to: state)
            }
            }, pointsUpdate: { [weak self] points in
                if let timeRaced = self?.timeRaced,
                    let raceType = self?.statRaceType {
                    StatsHelper.shared.completedRace(type: raceType,
                                                     points: points,
                                                     timeRaced: timeRaced)
                    PlayerMetrics.log(event: .raceCompleted,
                                      attributes: [
                                        "RaceType": raceType.rawValue,
                                        "Time": timeRaced,
                                        "Points": points
                        ])
                }
            }, linkCountUpdate: { [weak self] linkCount in
                self?.webView.text = linkCount.description
            }, logEvent: { [weak self] event in
                #if !MULTIWINDOWDEBUG
                    let metric = PlayerMetrics.Event(event: event)
                    if metric == .pageView,
                        let config = self?.networkConfig,
                        let raceType = StatsHelper.RaceType(config) {
                        StatsHelper.shared.viewedPage(raceType: raceType)
                    }
                    PlayerMetrics.log(event: metric, attributes: event.attributes)
                #endif
        })

        configureManagerControllerClosures()
    }

    private func configureManagerControllerClosures() {
        gameManager.voting(timeUpdate: { [weak self] time in
            self?.votingViewController?.voteTimeRemaing = time

            if self?.networkConfig.isHost ?? false && time == 0,
                let votingInfo = self?.gameManager.voteInfo {
                for index in 0..<votingInfo.pageCount {
                    if let info = votingInfo.page(for: index) {
                        for _ in 0..<info.votes {
                            PlayerMetrics.log(event: .finalVotes,
                                              attributes: ["Page": info.page.title as Any])
                        }
                    }
                }
            }
            }, infoUpdate: { [weak self] voteInfo in
                self?.votingViewController?.voteInfo = voteInfo
            }, finalPageUpdate: { [weak self] page in
                self?.finalPage = page
                self?.votingViewController?.finalPageSelected(page)

                UIView.animate(withDuration: WKRAnimationDurationConstants.gameFadeIn,
                               delay: WKRAnimationDurationConstants.gameFadeInDelay,
                               animations: {
                    self?.webView.alpha = 1.0
                }, completion: nil)
        })

        gameManager.results(showReady: { [weak self] showReady in
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

    private func errorOccurred(_ error: WKRFatalError) {
        guard self.view.window != nil  && !isPlayerQuitting else { return }
        isPlayerQuitting = true

        webView.isUserInteractionEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false

        let alertController = UIAlertController(title: error.title,
                                                message: error.message,
                                                preferredStyle: .alert)
        let quitAction = UIAlertAction(title: "Menu", style: .default) { [weak self] _ in
            self?.playerQuit()
        }
        alertController.addAction(quitAction)
        self.dismissActiveController(completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.present(alertController, animated: true, completion: nil)
                self.activeViewController = alertController
            })
        })

        PlayerMetrics.log(event: .fatalError,
                          attributes: ["Error": error.title as Any])
    }

    // MARK: - Controllers

    func resetActiveControllers() {
        alertController = nil
        votingViewController?.quitAlertController = nil
        votingViewController = nil
        resultsViewController?.quitAlertController = nil
        resultsViewController = nil
    }

    private func dismissActiveController(completion: (() -> Void)?) {
        func done() {
            resetActiveControllers()
            completion?()
        }
        if let activeViewController = activeViewController {
            if activeViewController.view.window != nil || activeViewController.presentedViewController?.view.window != nil{
                dismiss(animated: true, completion: {
                    done()
                })
            } else {
                done()
            }
        } else {
            done()
        }
    }

    // MARK: - Transitions

    private func transition(to state: WKRGameState) {
        guard !isPlayerQuitting, state != gameState else { return }
        gameState = state

        switch state {
        case .voting:
            transitionToVoting()
        case .results, .hostResults, .points:
            transitionToResults()
        case .race:
            transitionToRace()
        default: break
        }
    }

    private func transitionToVoting() {
        self.title = ""
        navigationController?.navigationBar.isHidden = true
        dismissActiveController(completion: { [weak self] in
            self?.showVotingController()
        })
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
    }

    private func showVotingController() {
        let controller = VotingViewController()
        controller.playerVoted = { [weak self] page in
            self?.gameManager.player(.voted(page))
            PlayerMetrics.log(event: .voted, attributes: ["Page": page.title as Any])

            if let raceType = self?.statRaceType {
                var stat = StatsHelper.Stat.mpcVotes
                switch raceType {
                case .mpc: stat = .mpcVotes
                case .gameKit: stat = .gkVotes
                case .solo: stat = .soloVotes
                default: break
                }
                StatsHelper.shared.increment(stat: stat)
            }
        }
        controller.voteInfo = gameManager.voteInfo
        controller.backupQuit = playerQuit
        controller.quitAlertController = quitAlertController(raceStarted: false)

        self.votingViewController = controller

        let navController = UINavigationController(rootViewController: controller)
        navController.modalTransitionStyle = .crossDissolve
        navController.modalPresentationStyle = .overCurrentContext
        present(navController, animated: true, completion: nil)
    }

    private func transitionToResults() {
        raceTimer?.invalidate()
        if activeViewController != resultsViewController || resultsViewController == nil {
            dismissActiveController(completion: { [weak self] in
                self?.showResultsController()
                UIView.animate(withDuration: WKRAnimationDurationConstants.gameFadeOut,
                               delay: WKRAnimationDurationConstants.gameFadeOutDelay,
                               options: .beginFromCurrentState,
                               animations: {
                                self?.webView.alpha = 0.0
                }, completion: nil)
            })
        } else {
            resultsViewController?.state = gameState
        }
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil

        if gameState == .hostResults && networkConfig.isHost {
            PlayerMetrics.log(event: .hostEndedRace)
        }

        connectingLabel.alpha = 0.0
        activityIndicatorView.alpha = 0.0
    }

    private func showResultsController() {
        let controller = ResultsViewController()
        controller.localPlayer = gameManager.localPlayer
        controller.readyButtonPressed = { [weak self] in
            self?.gameManager.player(.ready)
        }

        controller.addPlayersViewController = gameManager.hostNetworkInterface()
        controller.state = gameManager.gameState
        controller.resultsInfo = gameManager.hostResultsInfo
        controller.isPlayerHost = networkConfig.isHost
        controller.backupQuit = playerQuit
        controller.quitAlertController = quitAlertController(raceStarted: false)

        self.resultsViewController = controller

        let navController = UINavigationController(rootViewController: controller)
        navController.modalTransitionStyle = .crossDissolve
        navController.modalPresentationStyle = .overCurrentContext
        present(navController, animated: true, completion: nil)
    }

    private func transitionToRace() {
        navigationController?.navigationBar.isHidden = false
        timeRaced = 0
        raceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
            self?.timeRaced += 1
        })

        navigationController?.setNavigationBarHidden(false, animated: false)

        navigationItem.leftBarButtonItem = helpBarButtonItem
        navigationItem.rightBarButtonItem = quitBarButtonItem

        connectingLabel.alpha = 0.0
        activityIndicatorView.alpha = 0.0

        dismissActiveController(completion: nil)

        if networkConfig.isHost {
            PlayerMetrics.log(event: .hostStartedRace,
                              attributes: ["Page": finalPage?.title as Any])
        }
    }

}
