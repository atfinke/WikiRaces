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
        manager = WKRManager(networkConfig: config, stateUpdate: { [weak self] state, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorOccurred(error)
                }
            } else {
                self?.transition(to: state)
            }
            }, pointsUpdate: { [weak self] points in
                if let timeRaced = self?.timeRaced {
                    var isSolo = false
                    if case .solo? = self?.config {
                        isSolo = true
                    }
                    StatsHelper.shared.completedRace(points: points, timeRaced: timeRaced, isSolo: isSolo)
                }
            }, linkCountUpdate: { [weak self] linkCount in
                self?.webView.text = linkCount.description
            }, logEvent: { [weak self] event, attributes in
                #if !MULTIWINDOWDEBUG
                    guard let eventType = PlayerAnalytics.Event(rawValue: event) else {
                        fatalError("Invalid event " + event)
                    }
                    if eventType == .pageView {
                        var isSolo = false
                        if case .solo? = self?.config {
                            isSolo = true
                        }
                        StatsHelper.shared.viewedPage(isSolo: isSolo)
                    }
                    PlayerAnalytics.log(event: eventType, attributes: attributes)
                #endif
        })

        configureManagerControllerClosures()
    }

    private func configureManagerControllerClosures() {
        manager.voting(timeUpdate: { [weak self] time in
            self?.votingViewController?.voteTimeRemaing = time

            if self?.config.isHost ?? false && time == 0, let votingInfo = self?.manager.voteInfo {
                for index in 0..<votingInfo.pageCount {
                    if let info = votingInfo.page(for: index) {
                        for _ in 0..<info.votes {
                            PlayerAnalytics.log(event: .finalVotes, attributes: ["Page": info.page.title as Any])
                        }
                    }
                }
            }
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

    private func errorOccurred(_ error: WKRFatalError) {
        guard self.view.window != nil  && !isPlayerQuitting else { return }
        isPlayerQuitting = true

        webView.isUserInteractionEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false

        let alertController = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
        let quitAction = UIAlertAction(title: "Menu", style: .default) { [weak self] _ in
            self?.resetActiveControllers()
            NotificationCenter.default.post(name: NSNotification.Name("PlayerQuit"), object: nil)
        }
        alertController.addAction(quitAction)
        self.dismissActiveController(completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.present(alertController, animated: true, completion: nil)
                self.activeViewController = alertController
                PlayerAnalytics.log(presentingOf: alertController, on: self)

                UINotificationFeedbackGenerator().notificationOccurred(.error)
            })
        })

        PlayerAnalytics.log(event: .fatalError, attributes: ["Error": error.title as Any])
    }

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
            raceTimer?.invalidate()
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

            if state == .hostResults && config.isHost {
                PlayerAnalytics.log(event: .hostEndedRace)
            }
        case .race:
            timeRaced = 0
            raceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
                self?.timeRaced += 1
            })

            navigationController?.setNavigationBarHidden(false, animated: false)

            navigationItem.leftBarButtonItem = flagBarButtonItem
            navigationItem.rightBarButtonItem = quitBarButtonItem

            connectingLabel.alpha = 0.0
            activityIndicatorView.alpha = 0.0

            dismissActiveController(completion: nil)

            if config.isHost {
                PlayerAnalytics.log(event: .hostStartedRace, attributes: ["Page": self.finalPage?.title as Any])
            }
        default: break
        }
    }

}
