//
//  PlayerAnalytics.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/25/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import CloudKit
import Foundation

#if !MULTIWINDOWDEBUG
import Crashlytics
import FirebaseCore
#endif

struct PlayerAnalytics {

    // MARK: - Types

    enum ValueEvent {
        case usingGCAlias(String), usingDeviceName(String), usingCustomName(String)
        case updatedStats(points: Int, races: Int, totalTime: Int, fastestTime: Int, pages: Int)
    }

    enum Event: String {
        // Non Game
        case leaderboard, versionInfo
        case pressedJoin, pressedHost
        case namePromptResult, nameType
        // Game All Players
        case pageView
        case quitRace, forfeited, usedHelp, fatalError, backupQuit
        case openedHistory, pressedReadyButton, voted
        // Game Host
        case hostStartedMatch, hostStartedRace, hostEndedRace
        case hostCancelledPreMatch, hostStartMidMatchInviting
    }

    // MARK: - Events

    public static func log(event: Event, attributes: [String: Any]? = nil) {
        #if !MULTIWINDOWDEBUG
            Answers.logCustomEvent(withName: event.rawValue, customAttributes: attributes)
            if !(attributes?.values.flatMap({$0}).isEmpty ?? true) {
                Analytics.logEvent(event.rawValue, parameters: attributes)
            } else {
                Analytics.logEvent(event.rawValue, parameters: nil)
            }

        #endif
    }

    public static func log(event: ValueEvent) {
        #if !MULTIWINDOWDEBUG
            let container = CKContainer.default()
            container.fetchUserRecordID(completionHandler: { (recordID, _) in
                guard let recordID = recordID else { return }

                let publicDB = container.publicCloudDatabase
                publicDB.fetch(withRecordID: recordID, completionHandler: { (record, _) in
                    guard let record = record else { return }

                    switch event {
                    case .usingGCAlias(let alias):
                        record["GCAlias"] = alias as NSString
                        log(event: .nameType, attributes: ["Type": "GCAlias"])
                    case .usingDeviceName(let name):
                        record["DeviceName"] = name as NSString
                        log(event: .nameType, attributes: ["Type": "DeviceName"])
                    case .usingCustomName(let name):
                        record["CustomName"] = name as NSString
                        log(event: .nameType, attributes: ["Type": "CustomName"])
                    case .updatedStats(let points, let races, let totalTime, let fastestTime, let pages):
                        record["Points"] = NSNumber(value: points)
                        record["Races"] = NSNumber(value: races)
                        record["TotalTime"] = NSNumber(value: totalTime)
                        record["FastestTime"] = NSNumber(value: fastestTime)
                        record["Pages"] = NSNumber(value: pages)
                    }

                    publicDB.save(record, completionHandler: { (_, _) in })
                })
            })
        #endif
    }

}
