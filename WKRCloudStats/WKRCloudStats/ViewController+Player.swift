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

    // MARK: - CloudKit Querying

    func queryPlayerStats() {
        textView.textStorage?.append(NSAttributedString(string: "Querying Player Stats\n"))

        let query = CKQuery(recordType: "UserStats", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let queryOperation = CKQueryOperation(query: query)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = { record in
            self.playerRecords.append(record)
        }

        queryOperation.queryCompletionBlock = queryPlayerCompleted
        publicDB.add(queryOperation)
    }

    private func queryPlayerCompleted(cursor: CKQueryCursor?, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.textView.textStorage?.append(NSAttributedString(string: "Error: \(error)\n"))
                self.processPlayerStats()
            } else if let cursor = cursor {
                self.textView.textStorage?.append(NSAttributedString(string: "Querying w/ Cursor\n"))
                self.queryPlayerStats(cursor: cursor)
            } else {
                self.textView.textStorage?.append(NSAttributedString(string: "Got All Player Stats\n"))
                self.processPlayerStats()
            }
        }
    }

    private func queryPlayerStats(cursor: CKQueryCursor) {
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
        let keys = [
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
            "SoloTotalTime",
            "BundleVersion",
            "BundleBuild",
            "CreatedAt",
            "ModifiedAt"
        ]

        var csvString = ""
        for key in keys {
            csvString += key + ","
        }
        csvString += "\n"
        for record in playerRecords {
            for key in keys {
                if let object = record.object(forKey: key) {
                    csvString += "\(object)"
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
            try! csvString.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
