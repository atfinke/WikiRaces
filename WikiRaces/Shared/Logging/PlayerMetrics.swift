//
//  PlayerMetrics.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/25/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import CloudKit
import UIKit
import WKRKit

#if !MULTIWINDOWDEBUG
import Crashlytics
import FirebaseCore
#endif

internal struct PlayerMetrics {

    // MARK: - Logging Event Types

    enum ViewState: String {
        case didLoad
        case willAppear
        case didAppear
        case willDisappear
        case didDisappear
    }

    enum CrashLogEvent {
        case userAction(String)
        case viewState(String)
        case gameState(String)
    }

    // MARK: - Analytic Event Types

    enum StatEvent {
        case players(unique: Int, total: Int)
        case hasGCAlias(String), hasDeviceName(String), hasCustomName(String)
        case usingGCAlias(String), usingDeviceName(String), usingCustomName(String)
        case updatedStats(points: Int, races: Int, totalTime: Int, fastestTime: Int, pages: Int,
            soloTotalTime: Int, soloPages: Int, soloRaces: Int)
        case buildInfo(version: String, build: String)
    }

    enum Event: String {
        // Non Game
        case leaderboard, versionInfo
        case pressedJoin, pressedHost
        case namePromptResult, nameType
        case cloudStatus, interfaceMode

        // Game All Players
        case pageView, pageBlocked, pageError
        case quitRace, forfeited, usedHelp, fatalError, backupQuit
        case openedHistory, openedHistorySF, pressedReadyButton, voted
        case finalVotes

        // Game Host
        case hostStartedMatch, hostStartedRace, hostEndedRace
        case hostCancelledPreMatch, hostStartMidMatchInviting
        case hostStartedSoloMatch

        // Bugs
        case githubIssue41Hit // https://github.com/atfinke/WikiRaces/issues/41
    }

    // MARK: - Results Collection Types

    struct ProcessedResults {
        let csvURL: URL
        let playerCount: Int
        let totalPlayerTime: Int
        let links: Int
    }

    // MARK: - Logging Events

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

    public static func log(event: CrashLogEvent) {
        #if !MULTIWINDOWDEBUG
            switch event {
            case .userAction(let action):
                CLSNSLogv("UserAction: %@", getVaList([action]))
            case .viewState(let view):
                CLSNSLogv("ViewState: %@", getVaList([view]))
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
                    let userStatsRecordID = CKRecord.ID(recordName: statsRecordName as String)
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
                        case .hasGCAlias(let alias):
                            record["GCAlias"] = alias as NSString
                        case .hasDeviceName(let name):
                            record["DeviceName"] = name as NSString
                        case .hasCustomName(let name):
                            record["CustomName"] = name as NSString
                        case .updatedStats(let points, let races, let totalTime, let fastestTime, let pages,
                                           let soloTotalTime, let soloPages, let soloRaces):
                            record["Points"] = NSNumber(value: points)
                            record["Races"] = NSNumber(value: races)
                            record["TotalTime"] = NSNumber(value: totalTime)
                            record["FastestTime"] = NSNumber(value: fastestTime)
                            record["Pages"] = NSNumber(value: pages)
                            record["SoloTotalTime"] = NSNumber(value: soloTotalTime)
                            record["SoloPages"] = NSNumber(value: soloPages)
                            record["SoloRaces"] = NSNumber(value: soloRaces)
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

    // MARK: - Results Collection

    public static func record(results: WKRResultsInfo) {
        #if MULTIWINDOWDEBUG
            return
        #endif

        guard let processedResults = process(results: results) else { return }

        let resultsRecord = CKRecord(recordType: "RaceResult")
        resultsRecord["CSV"] = CKAsset(fileURL: processedResults.csvURL)
        resultsRecord["Links"] = NSNumber(value: processedResults.links)
        resultsRecord["PlayerCount"] = NSNumber(value: processedResults.playerCount)
        resultsRecord["TotalPlayerTime"] = NSNumber(value: processedResults.totalPlayerTime)

        CKContainer.default().publicCloudDatabase.save(resultsRecord) { (_, _) in
            try? FileManager.default.removeItem(at: processedResults.csvURL)
        }
    }

    private static func process(results: WKRResultsInfo) -> ProcessedResults? {

        func csvRow(for player: WKRPlayer, state: WKRPlayerState) -> String {

            func formatted(row: String?) -> String {
                return row?.replacingOccurrences(of: ",", with: " ") ?? ""
            }

            var string = ""
            string += formatted(row: player.name) + ","
            string += formatted(row: state.text) + ","

            if state == .foundPage {
                let time = String(player.raceHistory?.duration ?? 0)
                string += formatted(row: time) + ","
            } else {
                string += ","
            }

            for entry in player.raceHistory?.entries ?? [] {
                let title = (entry.page.title ?? "")
                let duration = String(entry.duration ?? 0)  + "|"
                string += formatted(row: duration + title) + ","
            }

            string.removeLast()

            return string
        }

        var links = 0
        var totalPlayerTime = 0

        var csvString = "Name,State,Duration,Pages\n"
        for index in 0..<results.playerCount {
            let raceResults = results.raceResults(at: index)

            links += raceResults.player.raceHistory?.entries.count ?? 0
            totalPlayerTime += raceResults.player.raceHistory?.duration ?? 0

            csvString += csvRow(for: raceResults.player, state: raceResults.playerState) + "\n"
        }

        guard let filePath = FileManager
            .default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .last?
            .path
            .appendingFormat("/\(Date()).csv") else {
                return nil
        }
        do {
            try csvString.write(toFile: filePath, atomically: true, encoding: .utf8)
            return ProcessedResults(csvURL: URL(fileURLWithPath: filePath),
                                    playerCount: results.playerCount,
                                    totalPlayerTime: totalPlayerTime,
                                    links: links)
        } catch {
            return nil
        }
    }

}
