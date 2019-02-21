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
                    let config = self?.networkConfig,
                    let raceType = StatsHelper.RaceType(config) {
                    StatsHelper.shared.completedRace(type: raceType,
                                                     points: points,
                                                     timeRaced: timeRaced)
                }
            }, linkCountUpdate: { [weak self] linkCount in
                self?.webView.text = linkCount.description
            }, logEvent: { [weak self] event, attributes in
                #if !MULTIWINDOWDEBUG
                    guard let eventType = PlayerMetrics.Event(rawValue: event) else {
                        fatalError("Invalid event " + event)
                    }
                    if eventType == .pageView,
                        let config = self?.networkConfig,
                        let raceType = StatsHelper.RaceType(config) {
                        StatsHelper.shared.viewedPage(raceType: raceType)
                    }
                    PlayerMetrics.log(event: eventType, attributes: attributes)
                #endif
        })

        configureManagerControllerClosures()
    }

    private func configureManagerControllerClosures() {
        gameManager.voting(timeUpdate: { [weak self] time in
            self?.votingViewController?.voteTimeRemaing = time

            if self?.networkConfig.isHost ?? false && time == 0, let votingInfo = self?.gameManager.voteInfo {
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
                UINotificationFeedbackGenerator().notificationOccurred(.error)
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
        dismissActiveController(completion: {
            self.performSegue(.showVoting)
        })
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
    }

    private func transitionToResults() {
        raceTimer?.invalidate()
        if activeViewController != resultsViewController || resultsViewController == nil {
            dismissActiveController(completion: {
                self.performSegue(.showResults)
                UIView.animate(withDuration: WKRAnimationDurationConstants.gameFadeOut,
                               delay: WKRAnimationDurationConstants.gameFadeOutDelay,
                               options: .beginFromCurrentState,
                               animations: {
                                self.webView.alpha = 0.0
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
