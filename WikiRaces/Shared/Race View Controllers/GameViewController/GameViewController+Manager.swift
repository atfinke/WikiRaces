//
//  GameViewController+Manager.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import WKRKit
import WKRUIKit

extension GameViewController {

    // MARK: - WKRGameManager -

    func setupGameManager() {
        gameManager = WKRGameManager(networkConfig: networkConfig,
                                     gameUpdate: { [weak self] gameUpdate in
                                        self?.gameUpdate(gameUpdate)
            }, votingUpdate: { [weak self] votingUpdate in
                self?.votingUpdate(votingUpdate)
            }, resultsUpdate: { [weak self] resultsUpdate in
                self?.resultsUpdate(resultsUpdate)
        })
    }

    private func gameUpdate(_ gameUpdate: WKRGameManager.GameUpdate) {
        switch gameUpdate {
        case .state(let state):
            PlayerAnonymousMetrics.log(event: .gameState("Transition: \(state)."))

            func startTransition(to state: WKRGameState) {
                transitionState = .inProgress
                transition(to: state, completion: { [weak self] in
                    guard let self = self else { return }
                    switch self.transitionState {
                    case .none, .inProgress:
                        self.transitionState = .none
                    case .quitting(let quitState):
                        if quitState == .waiting {
                            self.performQuit()
                        }
                    }
                })
            }

            if transitionState == .none {
                startTransition(to: state)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    startTransition(to: state)
                }
            }
        case .error(let error):
            DispatchQueue.main.async {
                self.errorOccurred(error)
            }
        case .log(let event):
            logEvent(event)
        case .playerRaceLinkCountForCurrentRace(let linkCount):
            webView?.text = linkCount.description
        case .playerStatsForLastRace(let points, let place, let webViewPixelsScrolled):
            processRaceStats(points: points, place: place, webViewPixelsScrolled: webViewPixelsScrolled)
        }
    }

    private func processRaceStats(points: Int, place: Int?, webViewPixelsScrolled: Int) {
        guard let raceType = statRaceType else { return }
        PlayerStatsManager.shared.completedRace(type: raceType,
                                                points: points,
                                                place: place,
                                                timeRaced: timeRaced,
                                                pixelsScrolled: webViewPixelsScrolled)

        let event: PlayerAnonymousMetrics.Event
        switch raceType {
        case .mpc:
            event = .mpcRaceCompleted
        case .gameKit:
            event = .gkRaceCompleted
        case .solo:
            event = .soloRaceCompleted
        }
        PlayerAnonymousMetrics.log(event: event,
                                   attributes: [
                                    "Time": timeRaced,
                                    "Points": points,
                                    "WebViewScrolled": webViewPixelsScrolled
            ])
    }

    private func votingUpdate(_ votingUpdate: WKRGameManager.VotingUpdate) {
        switch votingUpdate {
        case .remainingTime(let time):
            votingViewController?.voteTimeRemaing = time
            if time == 0 {
                logFinalVotes()
            }
        case .voteInfo(let voteInfo):
            votingViewController?.voteInfo = voteInfo
        case .finalPage(let page):
            finalPage = page
            votingViewController?.finalPageSelected(page)

            UIView.animate(withDuration: WKRAnimationDurationConstants.gameFadeIn,
                           delay: WKRAnimationDurationConstants.gameFadeInDelay,
                           animations: {
                            self.webView?.alpha = 1.0
            }, completion: nil)
        }
    }

    private func resultsUpdate(_ resultsUpdate: WKRGameManager.ResultsUpdate) {
        switch resultsUpdate {
        case .isReadyUpEnabled(let showReady):
            resultsViewController?.showReadyUpButton(showReady)
        case .remainingTime(let time):
            resultsViewController?.timeRemaining = time
        case .resultsInfo(let resultsInfo):
            if resultsViewController?.state != .hostResults {
                resultsViewController?.resultsInfo = resultsInfo
            }
        case .hostResultsInfo(let resultsInfo):
            resultsViewController?.resultsInfo = resultsInfo
        case .readyStates(let readyStates):
            resultsViewController?.readyStates = readyStates
        }
    }

    private func errorOccurred(_ error: WKRFatalError) {
        guard self.view.window != nil && !isErrorPresented else { return }
        isErrorPresented = true

        webView?.isUserInteractionEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false

        let alertController = UIAlertController(title: error.title,
                                                message: error.message,
                                                preferredStyle: .alert)
        let quitAction = UIAlertAction(title: "Menu", style: .default) { [weak self] _ in
            self?.attemptQuit()
        }
        alertController.addAction(quitAction)
        self.dismissActiveController(completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.present(alertController, animated: true, completion: nil)
                self.activeViewController = alertController
            })
        })

        let info = "errorOccurred: " + error.message
        PlayerAnonymousMetrics.log(event: .error(info))

        PlayerAnonymousMetrics.log(event: .fatalError,
                          attributes: ["Error": error.title as Any])
    }

    func logEvent(_ logEvent: WKRLogEvent) {
        #if !MULTIWINDOWDEBUG
        let metric = PlayerAnonymousMetrics.Event(event: logEvent)
        if metric == .pageView,
            let config = networkConfig,
            let raceType = PlayerStatsManager.RaceType(config) {
            PlayerStatsManager.shared.viewedPage(raceType: raceType)
        }
        PlayerAnonymousMetrics.log(event: metric, attributes: logEvent.attributes)
        #endif
    }

    // MARK: - Controllers -

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
            let viewWindow = activeViewController.view.window
            let presentedViewWindow = activeViewController.presentedViewController?.view.window
            if viewWindow != nil || presentedViewWindow != nil {
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

    // MARK: - Transitions -

    private func transition(to state: WKRGameState, completion: @escaping () -> Void) {
        guard state != gameState else {
            completion()
            return
        }

        gameState = state
        switch state {
        case .voting:
            transitionToVoting(completion: completion)
        case .results, .hostResults, .points:
            transitionToResults(completion: completion)
        case .race:
            transitionToRace(completion: completion)
        default:
            completion()
        }
    }

    private func transitionToVoting(completion: @escaping () -> Void) {
        self.title = ""
        navigationController?.navigationBar.isHidden = true
        dismissActiveController(completion: { [weak self] in
            self?.showVotingController(completion: completion)
        })
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
        setupNewWebView()
    }

    private func showVotingController(completion: @escaping () -> Void) {
        let controller = VotingViewController()
        controller.voteInfo = gameManager.voteInfo
        controller.quitAlertController = quitAlertController(raceStarted: false)
        controller.listenerUpdate = { [weak self] update in
            guard let self = self else { return }
            switch update {
            case .voted(let page):
                self.gameManager.player(.voted(page))
                // capitalized to keep consistent with past analytics
                PlayerAnonymousMetrics.log(event: .voted,
                                           attributes: ["Page": page.title?.capitalized as Any])

                if let raceType = self.statRaceType {
                    var stat = PlayerDatabaseStat.mpcVotes
                    switch raceType {
                    case .mpc: stat = .mpcVotes
                    case .gameKit: stat = .gkVotes
                    case .solo: stat = .soloVotes
                    }
                    stat.increment()
                }
            case .quit:
                self.attemptQuit()
            }
        }

        self.votingViewController = controller

        let navController = WKRUINavigationController(rootViewController: controller)
        navController.modalTransitionStyle = .crossDissolve
        navController.modalPresentationStyle = .overCurrentContext
        if #available(iOS 13.0, *) {
            navController.isModalInPresentation = true
        }

        present(navController, animated: true) { [weak self] in
            self?.connectingLabel.alpha = 0.0
            self?.activityIndicatorView.alpha = 0.0
            completion()
        }
    }

    private func transitionToResults(completion: @escaping () -> Void) {
        raceTimer?.invalidate()
        if activeViewController != resultsViewController || resultsViewController == nil {
            dismissActiveController(completion: { [weak self] in
                self?.showResultsController(completion: completion)
                UIView.animate(withDuration: WKRAnimationDurationConstants.gameFadeOut,
                               delay: WKRAnimationDurationConstants.gameFadeOutDelay,
                               options: .beginFromCurrentState,
                               animations: {
                                self?.webView?.alpha = 0.0
                }, completion: { [weak self] _ in
                    self?.title = nil
                    self?.navigationController?.setNavigationBarHidden(true, animated: false)
                })
            })
        } else {
            resultsViewController?.state = gameState
            completion()
        }
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil

        if gameState == .hostResults && networkConfig.isHost {
            PlayerAnonymousMetrics.log(event: .hostEndedRace)
        }
    }

    private func showResultsController(completion: @escaping () -> Void) {
        let controller = ResultsViewController()
        controller.localPlayer = gameManager.localPlayer
        controller.addPlayersViewController = gameManager.hostNetworkInterface()
        controller.state = gameManager.gameState
        controller.resultsInfo = gameManager.hostResultsInfo
        controller.isPlayerHost = networkConfig.isHost
        controller.quitAlertController = quitAlertController(raceStarted: false)

        controller.listenerUpdate = { [weak self] update in
            guard let self = self else { return }
            switch update {
            case .readyButtonPressed:
                self.gameManager.player(.ready)
            case .quit:
                self.attemptQuit()
            }
        }

        self.resultsViewController = controller

        let navController = WKRUINavigationController(rootViewController: controller)
        navController.modalTransitionStyle = .crossDissolve
        navController.modalPresentationStyle = .overCurrentContext
        if #available(iOS 13.0, *) {
            navController.isModalInPresentation = true
        }

        present(navController, animated: true) { [weak self] in
            self?.connectingLabel.alpha = 0.0
            self?.activityIndicatorView.alpha = 0.0
            completion()
        }
    }

    private func transitionToRace(completion: @escaping () -> Void) {
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

        dismissActiveController(completion: completion)

        if networkConfig.isHost {
            PlayerAnonymousMetrics.log(event: .hostStartedRace,
                              attributes: ["Page": finalPage?.title as Any])
        }
    }

    // MARK: - Log Final Votes -

    private func logFinalVotes() {
        guard networkConfig.isHost, let votingInfo = gameManager.voteInfo else { return }
        for index in 0..<votingInfo.pageCount {
            if let info = votingInfo.page(for: index) {
                for _ in 0..<info.votes {
                    // capitalized to keep consistent with past analytics
                    PlayerAnonymousMetrics.log(event: .finalVotes,
                                      attributes: ["Page": info.page.title?.capitalized as Any])
                }
            }
        }
    }
}
