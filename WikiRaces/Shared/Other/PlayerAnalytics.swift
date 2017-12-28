//
//  PlayerAnalytics.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/25/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import CloudKit

#if !MULTIWINDOWDEBUG
import Crashlytics
import FirebaseCore
#endif

struct PlayerAnalytics {

    // MARK: - Types

    enum ViewState: String {
        case didLoad
        case willAppear
        case didAppear
        case willDisappear
        case didDisappear
    }

    enum LogEvent {
        case userAction(String)
        case viewState(String)
    }

    enum StatEvent {
        case players(unique: Int, total: Int)
        case usingGCAlias(String), usingDeviceName(String), usingCustomName(String)
        case updatedStats(points: Int, races: Int, totalTime: Int, fastestTime: Int, pages: Int)
        case buildInfo(version: String, build: String)
    }

    enum Event: String {
        // Non Game
        case leaderboard, versionInfo
        case pressedJoin, pressedHost
        case namePromptResult, nameType

        // Game All Players
        case pageView, pageBlocked, pageError
        case quitRace, forfeited, usedHelp, fatalError, backupQuit
        case openedHistory, pressedReadyButton, voted
        case finalVotes

        // Game Host
        case hostStartedMatch, hostStartedRace, hostEndedRace
        case hostCancelledPreMatch, hostStartMidMatchInviting
    }

    // MARK: - Events

    public static func log(state: ViewState, for object: UIViewController) {
        log(event: .viewState("\(type(of: object)): " + state.rawValue))
    }

    public static func log(presentingOf modal: UIViewController, on object: UIViewController) {
        var titleString = "Title: "
        if let title = modal.title {
            titleString += title
        } else {
            titleString += "nil"
        }
        log(event: .viewState("\(type(of: object)): Presenting: \(type(of: modal)) " + titleString))
    }

    public static func log(event: LogEvent) {
        #if !MULTIWINDOWDEBUG
            switch event {
            case .userAction(let action):
                CLSNSLogv("UserAction: %@", getVaList([action]))
            case .viewState(let view):
                CLSNSLogv("ViewState: %@", getVaList([view]))
            }
        #endif
    }

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

    //swiftlint:disable:next cyclomatic_complexity function_body_length
    public static func log(event: StatEvent) {
        #if !MULTIWINDOWDEBUG
            let container = CKContainer.default()
            let publicDB = container.publicCloudDatabase

            // Fetch user record ID, then user record.
            container.fetchUserRecordID(completionHandler: { (userRecordID, _) in
                guard let userRecordID = userRecordID else { return }
                publicDB.fetch(withRecordID: userRecordID, completionHandler: { (userRecord, _) in
                    guard let userRecord = userRecord else { return }

                    // Get user stats record, or create new one.
                    let statsRecordName = userRecord.object(forKey: "UserStatsName") as? NSString ?? " "
                    let userStatsRecordID = CKRecordID(recordName: statsRecordName as String)
                    publicDB.fetch(withRecordID: userStatsRecordID, completionHandler: { (userStatsRecord, error) in

                        var userStatsRecord = userStatsRecord
                        if let error = error as? CKError, error.code == CKError.unknownItem {
                            userStatsRecord = CKRecord(recordType: "UserStats")
                        }
                        guard let record = userStatsRecord else { return }

                        // Update user stats record.
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
                        case .buildInfo(let version, let build):
                            record["BundleVersion"] = version as NSString
                            record["BundleBuild"] = build as NSString
                        case .players(let unique, let total):
                            record["TotalPlayers"] = NSNumber(value: total)
                            record["UniquePlayers"] = NSNumber(value: unique)
                        }

                        // Save updated stats record and update user record with stats record ID.
                        publicDB.save(record, completionHandler: { (savedUserStatsRecord, _) in
                            guard let savedUserStatsRecord = savedUserStatsRecord else { return }
                            userRecord["UserStatsName"] = savedUserStatsRecord.recordID.recordName as NSString
                            publicDB.save(userRecord, completionHandler: { (_, _) in })
                        })

                    })
                })
            })
        #endif
    }

}
