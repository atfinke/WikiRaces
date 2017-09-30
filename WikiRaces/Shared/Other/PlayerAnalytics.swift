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
#endif

struct PlayerAnalytics {

    // MARK: - Types

    enum ValueEvent {
        case usingGCAlias(String), usingDeviceName(String), usingCustomName(String)
        case updatedStats(points: Int, races: Int, totalTime: Int, fastestTime: Int)
    }

    enum Event: String {
        // All Players
        case pressedJoin, pressedHost
        case quitRace, forfeited, usedHelp, fatalError
        case openedHistory, pressedReadyButton, voted
        // Host
        case hostStartedMatch, hostStartedRace, hostEndedRace
        case hostCancelledPreMatch, hostStartMidMatchInviting
    }

    // MARK: - Events

    public static func log(event: Event) {
        #if !MULTIWINDOWDEBUG
            Answers.logCustomEvent(withName: event.rawValue, customAttributes: nil)
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
                    case .usingDeviceName(let name):
                        record["DeviceName"] = name as NSString
                    case .usingCustomName(let name):
                        record["CustomName"] = name as NSString
                    case .updatedStats(let points, let races, let totalTime, let fastestTime):
                        record["Points"] = NSNumber(value: points)
                        record["Races"] = NSNumber(value: races)
                        record["TotalTime"] = NSNumber(value: totalTime)
                        record["FastestTime"] = NSNumber(value: fastestTime)
                    }

                    publicDB.save(record, completionHandler: { (_, _) in })
                })
            })
        #endif
    }

}
