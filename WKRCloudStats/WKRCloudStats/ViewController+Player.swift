//
//  ViewController+Player.swift
//  WKRCloudStats
//
//  Created by Andrew Finke on 2/10/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import CloudKit
import Cocoa

extension ViewController {

    // MARK: - CloudKit Querying -

    func queryPlayerStats() {
        textView.textStorage?.append(NSAttributedString(string: "Querying Player Stats\n"))

        let recordType = isUsingUserStatsV3 ? "UserStatsv3" : "UserStats"
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let queryOperation = CKQueryOperation(query: query)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = { record in
            self.playerRecords.append(record)
        }

        queryOperation.queryCompletionBlock = queryPlayerCompleted
        publicDB.add(queryOperation)
    }

    private func queryPlayerCompleted(cursor: CKQueryOperation.Cursor?, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.textView.textStorage?.append(NSAttributedString(string: "Error: \(error)\n"))
                self.processPlayerStats()
            } else if let cursor = cursor {
                self.textView.textStorage?.append(NSAttributedString(string: "Querying w/ Cursor \(self.playerRecords.count)\n"))
                self.queryPlayerStats(cursor: cursor)
            } else {
                self.textView.textStorage?.append(NSAttributedString(string: "Got All Player Stats\n"))
                self.processPlayerStats()
            }
        }
    }

    private func queryPlayerStats(cursor: CKQueryOperation.Cursor) {
        let queryOperation = CKQueryOperation(cursor: cursor)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = { record in
            self.playerRecords.append(record)
        }

        queryOperation.queryCompletionBlock = queryPlayerCompleted
        publicDB.add(queryOperation)
    }

    // MARK: - Processing

    private func processPlayerStats() {
        let v1Keys = [
            "CustomName",
            "DeviceName",
            "GCAlias",
            "Points",
            "Races",
            "Pages",
            "FastestTime",
            "TotalTime",
            "UniquePlayers",
            "TotalPlayers",
            "SoloPages",
            "SoloRaces",
            "SoloTotalTime",
            "BundleVersion",
            "BundleBuild",
            "CreatedAt",
            "ModifiedAt"
        ]

        let v3Keys = [
            "CustomNames",
            "DeviceNames",
            "GCAliases",

            "gkFastestTime",
            "gkHelp",
            "gkInvitedToMatch",
            "gkMatch",
            "gkPages",
            "gkPixelsScrolled",
            "gkPoints",
            "gkPressedJoin",
            "gkRaceDNF",
            "gkRaceFinishFirst",
            "gkRaceFinishSecond",
            "gkRaceFinishThird",
            "gkRaces",
            "gkTotalPlayers",
            "gkTotalTime",
            "gkUniquePlayers",
            "gkVotes",
            "mpcFastestTime",
            "mpcHelp",
            "mpcMatch",
            "mpcPages",
            "mpcPixelsScrolled",
            "mpcPoints",
            "mpcPressedHost",
            "mpcPressedJoin",
            "mpcRaceDNF",
            "mpcRaceFinishFirst",
            "mpcRaceFinishSecond",
            "mpcRaceFinishThird",
            "mpcRaces",
            "mpcTotalPlayers",
            "mpcTotalTime",
            "mpcUniquePlayers",
            "mpcVotes",
            "multiplayerAverage",
            "soloFastestTime",
            "soloHelp",
            "soloMatch",
            "soloPages",
            "soloPixelsScrolled",
            "soloPressedHost",
            "soloRaceDNF",
            "soloRaceFinishFirst",
            "soloRaces",
            "soloTotalTime",
            "soloVotes",
            "triggeredEasterEgg",

            "osVersion",
            "coreVersion",
            "coreBuild",
            "CreatedAt",
            "ModifiedAt"
        ]

        let keys = isUsingUserStatsV3 ? v3Keys : v1Keys

        var csvString = ""
        for key in keys {
            csvString += key + ","
        }
        csvString += "\n"
        for record in playerRecords {
            for key in keys {
                if let object = record.object(forKey: key) {
                    csvString += "\(object)".replacingOccurrences(of: ",", with: "|").replacingOccurrences(of: "\n", with: "")
                } else if key == "CreatedAt", let date = record.creationDate {
                    csvString += "\(date)"
                } else if key == "ModifiedAt", let date = record.modificationDate {
                    csvString += "\(date)"
                }
                csvString += ","
            }
            csvString += "\n"
        }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "WKRCloudStats.csv"
        panel.beginSheetModal(for: self.view.window!) { _ in
            guard let url = panel.url else { return }
            try? csvString.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
