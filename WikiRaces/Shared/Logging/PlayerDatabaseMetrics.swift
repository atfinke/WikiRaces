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

class PlayerDatabaseMetrics: NSObject {

    // MARK: - Types

    enum PlayerDatabaseEvent {
        case players(unique: Int, total: Int)
        case gcAlias(String), deviceName(String), customName(String)
        case syncStats(points: Int, races: Int, totalTime: Int, fastestTime: Int, pages: Int,
            soloTotalTime: Int, soloPages: Int, soloRaces: Int)
        case build(version: String, build: String)
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

    private var queuedEvents = [PlayerDatabaseEvent]()

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
                guard let statsRecordName = userRecord.object(forKey: "UserStatsName") as? NSString,
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

        let userStatsRecord = CKRecord(recordType: "UserStats")
        userStatsRecord["DeviceName"] = UIDevice.current.name as NSString
        publicDB.save(userStatsRecord, completionHandler: { (savedUserStatsRecord, _) in
            guard let savedUserStatsRecord = savedUserStatsRecord else {
                self.isCreatingStatsRecord = false
                return
            }
            userRecord["UserStatsName"] = savedUserStatsRecord.recordID.recordName as NSString

            self.publicDB.save(userRecord, completionHandler: { (savedUserRecord, _) in
                self.userRecord = savedUserRecord
                self.userStatsRecord = savedUserStatsRecord
                self.isCreatingStatsRecord = false
                self.sync()
            })
        })
    }

    // MARK: - Events

    func log(event: PlayerDatabaseEvent) {
        queuedEvents.append(event)
        sync()
    }

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
                record["GCAlias"] = alias as NSString
            case .deviceName(let name):
                record["DeviceName"] = name as NSString
            case .customName(let name):
                record["CustomName"] = name as NSString
            case .syncStats(let points,
                            let races,
                            let totalTime,
                            let fastestTime,
                            let pages,
                            let soloTotalTime,
                            let soloPages,
                            let soloRaces):
                record["Points"] = NSNumber(value: points)
                record["Races"] = NSNumber(value: races)
                record["TotalTime"] = NSNumber(value: totalTime)
                record["FastestTime"] = NSNumber(value: fastestTime)
                record["Pages"] = NSNumber(value: pages)
                record["SoloTotalTime"] = NSNumber(value: soloTotalTime)
                record["SoloPages"] = NSNumber(value: soloPages)
                record["SoloRaces"] = NSNumber(value: soloRaces)
            case .build(let version, let build):
                record["BundleVersion"] = version as NSString
                record["BundleBuild"] = build as NSString
            case .players(let unique, let total):
                record["TotalPlayers"] = NSNumber(value: total)
                record["UniquePlayers"] = NSNumber(value: unique)
            }
        }

        publicDB.save(record) { (savedUserStatsRecord, _) in
            if let savedUserStatsRecord = savedUserStatsRecord {
                self.userStatsRecord = savedUserStatsRecord
            } else {
                self.queuedEvents = events + self.queuedEvents
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


