//
//  PlayerMetrics.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/25/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

#if !MULTIWINDOWDEBUG
import Crashlytics
import FirebaseCore
#endif

internal struct PlayerAnonymousMetrics {

    // MARK: - Logging Event Types

    enum CrashLogEvent {
        case userAction(String)
        case gameState(String)
    }

    // MARK: - Analytic Event Types

    enum Event: String {
        // Non Game
        case leaderboard, versionInfo
        case pressedJoin, pressedHost, pressedGlobalJoin, pressedLocalOptions
        case namePromptResult, nameType
        case cloudStatus, interfaceMode

        // Game All Players
        case pageView, pageBlocked, pageError
        case quitRace, forfeited, usedHelp, usedReload, fatalError, backupQuit
        case openedHistory, openedHistorySF, openedShare, pressedReadyButton, voted
        case finalVotes
        case linkOnPage, missedLink, foundPage, pageLoadingError

        // Game Host
        case hostStartedMatch, hostStartedRace, hostEndedRace
        case hostCancelledPreMatch, hostStartMidMatchInviting
        case hostStartedSoloMatch
        case globalFailedToFindHost

        case raceCompleted
        case banHammer
        case connectionTestResult
        case displayedMedals

        case collectiveVotingArticlesSeen, localVotingArticlesSeen, localVotingArticlesReset
        case votingArticleValidationFailure, votingArticlesWeightedTiebreak

        //swiftlint:disable:next cyclomatic_complexity
        init(event: WKRLogEvent) {
            switch event.type {
            case .linkOnPage:       self = .linkOnPage
            case .foundPage:        self = .foundPage
            case .pageBlocked:      self = .pageBlocked
            case .pageLoadingError: self = .pageLoadingError
            case .pageView:         self = .pageView
            case .missedLink:       self = .missedLink

            case .collectiveVotingArticlesSeen:     self = .collectiveVotingArticlesSeen
            case .localVotingArticlesSeen:          self = .localVotingArticlesSeen
            case .localVotingArticlesReset:         self = .localVotingArticlesReset
            case .votingArticleValidationFailure:   self = .votingArticleValidationFailure
            case .votingArticlesWeightedTiebreak:   self = .votingArticlesWeightedTiebreak
            }
        }
    }

    // MARK: - Logging Events

    public static func log(event: CrashLogEvent) {
        #if MULTIWINDOWDEBUG
        switch event {
        case .userAction(let action):
            print("UserAction: ", action)
        case .gameState(let description):
            print("GameState: ", description)
        }
        #else
        switch event {
        case .userAction(let action):
            CLSNSLogv("UserAction: %@", getVaList([action]))
        case .gameState(let description):
            CLSNSLogv("GameState: %@", getVaList([description]))
}
        #endif
    }

    // MARK: - Analytic Events

    public static func log(event: Event, attributes: [String: Any]? = nil) {
        #if !MULTIWINDOWDEBUG && !DEBUG
            Answers.logCustomEvent(withName: event.rawValue, customAttributes: attributes)
        if !(attributes?.values.compactMap { $0 }.isEmpty ?? true) {
                Analytics.logEvent(event.rawValue, parameters: attributes)
            } else {
                Analytics.logEvent(event.rawValue, parameters: nil)
            }
        #endif
    }
}
