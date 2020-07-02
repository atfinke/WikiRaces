//
//  PlayerMetrics.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/25/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

#if !targetEnvironment(macCatalyst) && !MULTIWINDOWDEBUG
import FirebaseAnalytics
import FirebaseCrashlytics
#endif

internal struct PlayerFirebaseAnalytics {

    // MARK: - Logging Event Types

    enum CrashLogEvent {
        case userAction(String)
        case gameState(String)
        case error(String)
    }

    // MARK: - Analytic Event Types

    enum Event: String {
        // Non Game
        case leaderboard, versionInfo
        case revampPressedHost, revampPressedJoinPublic, revampPressedJoinPrivate, revampPressedHostiCloudIssue
        case namePromptResult, nameType
        case cloudStatus, interfaceMode, autoInviteToggled, autoInviteState

        // Game All Players
        case pageView, pageBlocked, pageError
        case quitRace, forfeited, usedHelp, usedReload, fatalError, backupQuit
        case openedHistory, openedHistorySF, openedShare, pressedReadyButton, voted
        case finalVotes
        case linkOnPage, missedLink, foundPage, pageLoadingError
        case finishedProfilePhotoFetch

        // Game Host
        case hostStartedMatch, hostStartedRace, hostEndedRace
        case hostCancelledPreMatch, hostStartMidMatchInviting
        case hostStartedSoloMatch
        case globalFailedToFindHost
        case customRaceOpened

        case mpcRaceCompleted, gkRaceCompleted, soloRaceCompleted
        case banHammer
        case connectionTestResult
        case displayedMedals, puzzleViewScrolled

        case collectiveVotingArticlesSeen, localVotingArticlesSeen, localVotingArticlesReset
        case votingArticleValidationFailure, votingArticlesWeightedTiebreak

        case automaticResultsImageSave
        case forcedIntoStoreFromCustomize
        case forcedIntoStoreFromStats

        case raceCodeGKSuccess
        case raceCodeGKFailed
        case raceCodeShared

        case raceCodeRecordReused
        case raceCodeRecordTooRecent
        case raceCodeRecordCreated

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
        #if MULTIWINDOWDEBUG || targetEnvironment(macCatalyst)
        switch event {
        case .userAction(let action):
            print("UserAction: ", action)
        case .gameState(let description):
            print("GameState: ", description)
        case .error(let error):
            print("Error: ", error)
        }
        #else
        switch event {
        case .userAction(let action):
            Crashlytics.crashlytics().log("UserAction: \(action)")
        case .gameState(let description):
            Crashlytics.crashlytics().log("GameState: \(description)")
        case .error(let error):
            Crashlytics.crashlytics().log("LoggedError: \(error)")
        }
        #endif
    }

    // MARK: - Analytic Events

    public static func log(event: Event, attributes: [String: Any]? = nil) {
        #if !targetEnvironment(macCatalyst) && !MULTIWINDOWDEBUG && !DEBUG
        if !(attributes?.values.compactMap { $0 }.isEmpty ?? true) {
            Analytics.logEvent(event.rawValue, parameters: attributes)
        } else {
            Analytics.logEvent(event.rawValue, parameters: nil)
        }
        #endif
    }
}
