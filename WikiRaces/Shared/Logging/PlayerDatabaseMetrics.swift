//
//  PlayerDatabaseMetrics.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/29/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import CloudKit
import UIKit

import WKRKit

//swiftlint:disable:next type_body_length
class PlayerDatabaseMetrics: NSObject {

    // MARK: - Types

    enum Event {
        case players(mpcUnique: Int, mpcTotal: Int, gkUnique: Int, gkTotal: Int)
        case gcAlias(String), deviceName(String), customName(String)
        case app(coreVersion: String, coreBuild: Int, kitConstants: Int, uiKitConstants: Int)

        //swiftlint:disable:next line_length
        case mpcStatsUpdate(mpcPoints: Int, mpcRaces: Int, mpcFastestTime: Int, mpcTotalTime: Int, mpcPages: Int, mpcPressedJoin: Int, mpcPressedHost: Int)
        //swiftlint:disable:next line_length
        case gkStatsUpdate(gkPoints: Int, gkRaces: Int, gkFastestTime: Int, gkTotalTime: Int, gkPages: Int, gkPressedJoin: Int, gkConnectedToMatch: Int)
        case soloStatsUpdate(soloRaces: Int, soloTotalTime: Int, soloPages: Int)
    }

    private struct ProcessedResults {
        let csvURL: URL
        let playerCount: Int
        let totalPlayerTime: Int
        let links: Int
    }

    // MARK: - Properties

    static var shared = PlayerDatabaseMetrics()

    private let container = CKContainer.default()
    private let publicDB = CKContainer.default().publicCloudDatabase

    private var userRecord: CKRecord?
    private var userStatsRecord: CKRecord?

    private var isConnecting = false
    private var isCreatingStatsRecord = false
    private var isSyncing = false

    private var queuedEvents = [Event]()

    // MARK: - Connecting

    func connect() {
        #if MULTIWINDOWDEBUG
        return
        #endif

        guard !isConnecting else { return }
        isConnecting = true

        container.fetchUserRecordID(completionHandler: { (userRecordID, _) in
            guard let userRecordID = userRecordID else {
                self.isConnecting = false
                return
            }
            self.publicDB.fetch(withRecordID: userRecordID, completionHandler: { (userRecord, _) in
                self.userRecord = userRecord
                guard let userRecord = userRecord else {
                    self.isConnecting = false
                    return
                }

                // Get user stats record, or create new one.
                guard let statsRecordName = userRecord.object(forKey: "UserStatsNamev2") as? NSString,
                    statsRecordName.length > 5 else {
                        self.createUserStatsRecord()
                        self.isConnecting = false
                        return
                }
                let userStatsRecordID = CKRecord.ID(recordName: statsRecordName as String)
                self.publicDB.fetch(withRecordID: userStatsRecordID, completionHandler: { (userStatsRecord, error) in
                    if let error = error as? CKError, error.code == CKError.unknownItem {
                        self.createUserStatsRecord()
                        self.isConnecting = false
                        return
                    }
                    guard let userStatsRecord = userStatsRecord else { return }
                    self.userStatsRecord = userStatsRecord
                    self.isConnecting = false
                    self.sync()
                })
            })
        })
    }

    private func createUserStatsRecord() {
        guard let userRecord = userRecord, !isCreatingStatsRecord else { return }
        isCreatingStatsRecord = true

        let userStatsRecord = CKRecord(recordType: "UserStatsv2")
        userStatsRecord["DeviceNames"] = [UIDevice.current.name] as NSArray
        publicDB.save(userStatsRecord, completionHandler: { (savedUserStatsRecord, _) in
            guard let savedUserStatsRecord = savedUserStatsRecord else {
                self.isCreatingStatsRecord = false
                return
            }
            userRecord["UserStatsNamev2"] = savedUserStatsRecord.recordID.recordName as NSString

            self.publicDB.save(userRecord, completionHandler: { (savedUserRecord, _) in
                self.userRecord = savedUserRecord
                self.userStatsRecord = savedUserStatsRecord
                self.isCreatingStatsRecord = false
                self.sync()
            })
        })
    }

    // MARK: - Events

    func log(event: Event) {
        queuedEvents.append(event)

        // Often, multiple logs are called at once resulting in multiple db syncs.
        // This adds a bit of a delay so we can coalesce syncs more often.
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.25) {
            self.sync()
        }
    }

    //swiftlint:disable:next function_body_length cyclomatic_complexity
    private func sync() {
        guard !queuedEvents.isEmpty,
               !isConnecting,
                !isCreatingStatsRecord,
                 !isSyncing,
                  let record = userStatsRecord else { return }

        isSyncing = true
        let events = queuedEvents
        queuedEvents = []

        for event in events {
            switch event {
            case .gcAlias(let alias):
                var names = [String]()
                if let existingNames = record["GCAliases"] as? NSArray as? [String] {
                    names.append(contentsOf: existingNames)
                }
                names.append(alias)
                record["GCAliases"] = Array(Set(names)) as NSArray
            case .deviceName(let name):
                var names = [String]()
                if let existingNames = record["DeviceNames"] as? NSArray as? [String] {
                    names.append(contentsOf: existingNames)
                }
                names.append(name)
                record["DeviceNames"] = Array(Set(names)) as NSArray
            case .customName(let name):
                var names = [String]()
                if let existingNames = record["CustomNames"] as? NSArray as? [String] {
                    names.append(contentsOf: existingNames)
                }
                names.append(name)
                record["CustomNames"] = Array(Set(names)) as NSArray
            case .mpcStatsUpdate(let mpcPoints,
                                 let mpcRaces,
                                 let mpcFastestTime,
                                 let mpcTotalTime,
                                 let mpcPages,
                                 let mpcPressedJoin,
                                 let mpcPressedHost):
                record["mpcPoints"] = NSNumber(value: mpcPoints)
                record["mpcRaces"] = NSNumber(value: mpcRaces)
                record["mpcPages"] = NSNumber(value: mpcPages)
                record["mpcFastestTime"] = NSNumber(value: mpcFastestTime)
                record["mpcTotalTime"] = NSNumber(value: mpcTotalTime)
                record["mpcPressedJoin"] = NSNumber(value: mpcPressedJoin)
                record["mpcPressedHost"] = NSNumber(value: mpcPressedHost)
            case .gkStatsUpdate(let gkPoints,
                                let gkRaces,
                                let gkFastestTime,
                                let gkTotalTime,
                                let gkPages,
                                let gkPressedJoin,
                                let gkConnectedToMatch):
                record["gkPoints"] = NSNumber(value: gkPoints)
                record["gkRaces"] = NSNumber(value: gkRaces)
                record["gkPages"] = NSNumber(value: gkPages)
                record["gkFastestTime"] = NSNumber(value: gkFastestTime)
                record["gkTotalTime"] = NSNumber(value: gkTotalTime)
                record["gkPressedJoin"] = NSNumber(value: gkPressedJoin)
                record["gkConnectedToMatch"] = NSNumber(value: gkConnectedToMatch)
            case .soloStatsUpdate(let soloRaces, let soloTotalTime, let soloPages):
                record["soloRaces"] = NSNumber(value: soloRaces)
                record["soloTotalTime"] = NSNumber(value: soloTotalTime)
                record["soloPages"] = NSNumber(value: soloPages)
            case .app(let coreVersion, let coreBuild, let kitConstants, let uiKitConstants):
                record["coreVersion"] = coreVersion as NSString
                record["coreBuild"] = coreBuild.description as NSString
                record["WKRKitConstantsVersion"] = kitConstants.description as NSString
                record["WKRUIKitConstantsVersion"] = uiKitConstants.description as NSString
            case .players(let mpcUnique, let mpcTotal, let gkUnique, let gkTotal):
                record["mpcUnique"] = NSNumber(value: mpcUnique)
                record["mpcTotal"] = NSNumber(value: mpcTotal)
                record["gkUnique"] = NSNumber(value: gkUnique)
                record["gkTotal"] = NSNumber(value: gkTotal)
            }
        }

        publicDB.save(record) { (savedUserStatsRecord, _) in
            if let savedUserStatsRecord = savedUserStatsRecord {
                self.userStatsRecord = savedUserStatsRecord
            } else {
                self.userStatsRecord = nil
                self.userRecord = nil

                let newEvents = events + self.queuedEvents
                self.queuedEvents = newEvents
                self.connect()
            }
            self.isSyncing = false
            self.sync()
        }
    }

    // MARK: - Results Collection

    func record(results: WKRResultsInfo) {
        #if MULTIWINDOWDEBUG
        return
        #endif

        guard let processedResults = process(results: results) else { return }

        let resultsRecord = CKRecord(recordType: "RaceResult")
        resultsRecord["CSV"] = CKAsset(fileURL: processedResults.csvURL)
        resultsRecord["Links"] = NSNumber(value: processedResults.links)
        resultsRecord["PlayerCount"] = NSNumber(value: processedResults.playerCount)
        resultsRecord["TotalPlayerTime"] = NSNumber(value: processedResults.totalPlayerTime)

        publicDB.save(resultsRecord) { (_, _) in
            try? FileManager.default.removeItem(at: processedResults.csvURL)
        }
    }

    private func process(results: WKRResultsInfo) -> ProcessedResults? {

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
            let player = results.raceRankingsPlayer(at: index)

            links += player.raceHistory?.entries.count ?? 0
            totalPlayerTime += player.raceHistory?.duration ?? 0

            csvString += csvRow(for: player, state: player.state) + "\n"
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
