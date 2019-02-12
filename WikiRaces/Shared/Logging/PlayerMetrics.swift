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

internal struct PlayerMetrics {

    // MARK: - Logging Event Types

    enum CrashLogEvent {
        case userAction(String)
        case gameState(String)
    }

    // MARK: - Analytic Event Types

    enum Event: String {
        // Non Game
        case leaderboard, versionInfo
        case pressedJoin, pressedHost
        case namePromptResult, nameType
        case cloudStatus, interfaceMode

        // Game All Players
        case pageView, pageBlocked, pageError
        case quitRace, forfeited, usedHelp, fatalError, backupQuit
        case openedHistory, openedHistorySF, openedShare, pressedReadyButton, voted
        case finalVotes

        // Game Host
        case hostStartedMatch, hostStartedRace, hostEndedRace
        case hostCancelledPreMatch, hostStartMidMatchInviting
        case hostStartedSoloMatch
        
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
