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
        gameManager = WKRGameManager(
            networkConfig: networkConfig,
            settings: gameSettings,
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
            PlayerFirebaseAnalytics.log(event: .gameState("Transition: \(state)."))

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

            if networkConfig.isHost {
                PlayerCloudKitLiveRaceManager.shared.updated(state: state)
            }
        case .error(let error):
            DispatchQueue.main.async {
                self.errorOccurred(error)
            }
        case .log(let event):
            logEvent(event)
        case .playerRaceLinkCountForCurrentRace(let linkCount):
            webView?.text = linkCount.description
        case .playerStatsForLastRace(let points, let place, let webViewPixelsScrolled, let pages):
            processRaceStats(points: points, place: place, webViewPixelsScrolled: webViewPixelsScrolled, pages: pages)
        }
    }

    private func processRaceStats(points: Int, place: Int?, webViewPixelsScrolled: Int, pages: [WKRPage]) {
        guard let raceType = statRaceType else { return }
        PlayerStatsManager.shared.completedRace(
            type: raceType,
            points: points,
            place: place,
            timeRaced: timeRaced,
            pixelsScrolled: webViewPixelsScrolled,
            pages: pages,
            isEligibleForPoints: gameSettings.points.isStandard,
            isEligibleForSpeed: gameSettings.startPage.isStandard)

        let event: PlayerFirebaseAnalytics.Event
        switch raceType {
        case .private:
            event = .mpcRaceCompleted
        case .public:
            event = .gkRaceCompleted
        case .solo:
            event = .soloRaceCompleted
        }
        PlayerFirebaseAnalytics.log(
            event: event,
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
        case .votingState(let votingState):
            votingViewController?.votingState = votingState
        case .raceConfig(let config):
            finalPage = config.endingPage
            votingViewController?.finalPageSelected(config.endingPage)

            votingViewController?.backingAlpha = 1
            view.alpha = 1
            UIView.animate(
                withDuration: WKRAnimationDurationConstants.gameFadeIn,
                delay: WKRAnimationDurationConstants.gameFadeInDelay,
                animations: { [weak self] in
                    self?.votingViewController?.backingAlpha = 0
                }, completion: nil)

            // Because web view is a pain, force relayout
            navigationController?.setNavigationBarHidden(true, animated: false)
            navigationController?.setNavigationBarHidden(false, animated: false)
            
            PlayerCloudKitLiveRaceManager.shared.updated(config: config)
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
            if networkConfig.isHost {
                PlayerCloudKitLiveRaceManager.shared.updated(resultsInfo: resultsInfo)
            }
        case .hostResultsInfo(let resultsInfo):
            resultsViewController?.resultsInfo = resultsInfo
            if networkConfig.isHost {
                PlayerCloudKitLiveRaceManager.shared.updated(resultsInfo: resultsInfo)
            }
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

        let alertController = UIAlertController(
            title: error.title,
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
        PlayerFirebaseAnalytics.log(event: .error(info))

        PlayerFirebaseAnalytics.log(event: .fatalError,
                                   attributes: ["Error": error.title as Any])
    }

    func logEvent(_ logEvent: WKRLogEvent) {
        #if !MULTIWINDOWDEBUG
        let metric = PlayerFirebaseAnalytics.Event(event: logEvent)
        if metric == .pageView,
            let raceType = PlayerStatsManager.RaceType(networkConfig) {
            PlayerStatsManager.shared.viewedPage(raceType: raceType)
        }
        PlayerFirebaseAnalytics.log(event: metric, attributes: logEvent.attributes)
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
        controller.votingState = gameManager.votingState
        controller.quitAlertController = quitAlertController(raceStarted: false)
        controller.listenerUpdate = { [weak self] update in
            guard let self = self else { return }
            switch update {
            case .voted(let page):
                self.gameManager.player(.voted(page))
                // capitalized to keep consistent with past analytics
                PlayerFirebaseAnalytics.log(event: .voted,
                                           attributes: ["Page": page.title?.capitalized as Any])

                if let raceType = self.statRaceType {
                    var stat = PlayerUserDefaultsStat.mpcVotes
                    switch raceType {
                    case .private: stat = .mpcVotes
                    case .public: stat = .gkVotes
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
        navController.isModalInPresentation = true

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
            })
        } else {
            resultsViewController?.state = gameState
            completion()
        }
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil

        if gameState == .hostResults && networkConfig.isHost {
            PlayerFirebaseAnalytics.log(event: .hostEndedRace)
        }
    }

    private func showResultsController(completion: @escaping () -> Void) {
        let controller = ResultsViewController()
        controller.backingAlpha = 0
        controller.localPlayer = gameManager.localPlayer
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
        navController.isModalInPresentation = true

        present(navController, animated: true) { [weak self] in
            self?.connectingLabel.alpha = 0.0
            self?.activityIndicatorView.alpha = 0.0
            completion()

            UIView.animate(
                withDuration: WKRAnimationDurationConstants.gameFadeOut,
                delay: WKRAnimationDurationConstants.gameFadeOutDelay,
                options: .beginFromCurrentState,
                animations: {
                    controller.backingAlpha = 1
            }, completion: { [weak self] _ in
                self?.title = nil
                self?.view.alpha = 0
            })
        }

    }

    private func transitionToRace(completion: @escaping () -> Void) {
        navigationController?.navigationBar.isHidden = false
        timeRaced = 0
        raceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
            self?.timeRaced += 1
        })

        navigationItem.leftBarButtonItem = helpBarButtonItem
        navigationItem.rightBarButtonItem = quitBarButtonItem

        connectingLabel.alpha = 0.0
        activityIndicatorView.alpha = 0.0

        dismissActiveController(completion: completion)

        if networkConfig.isHost {
            PlayerFirebaseAnalytics.log(
                event: .hostStartedRace,
                attributes: [
                    "Page": finalPage?.title as Any,
                    "Custom": gameSettings.isCustom ? 1 : 0
            ])
        }
    }

    // MARK: - Log Final Votes -

    private func logFinalVotes() {
        guard networkConfig.isHost, let votingState = gameManager.votingState else { return }
        for item in votingState.current {
            for _ in 0..<item.voters.count {
                // capitalized to keep consistent with past analytics
                PlayerFirebaseAnalytics.log(event: .finalVotes,
                                           attributes: ["Page": item.page.title?.capitalized as Any])
            }
        }
    }
}
