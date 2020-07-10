//
//  ViewController+Race.swift
//  WKRCloudStats
//
//  Created by Andrew Finke on 2/10/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import CloudKit
import Cocoa

extension ViewController {

    // MARK: - CloudKit Querying

    func queryRaceStats() {
        textView.textStorage?.append(NSAttributedString(string: "Querying Race Stats\n"))

        let query = CKQuery(recordType: "RaceResult", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "Links", ascending: false)]

        let queryOperation = CKQueryOperation(query: query)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = { record in
            self.raceRecords.append(record)
        }

        queryOperation.queryCompletionBlock = queryRaceCompleted(cursor:error:)
        publicDB.add(queryOperation)
    }

    private func queryRaceCompleted(cursor: CKQueryOperation.Cursor?, error: Error?) {

        DispatchQueue.main.async {

            if self.raceRecords.count > 200 {
            self.processRaceStats()
                        return
                    }

            if let error = error {
                self.textView.textStorage?.append(NSAttributedString(string: "Error: \(error)\n"))
                self.processRaceStats()
            } else if let cursor = cursor {
                self.textView.textStorage?.append(NSAttributedString(string: "Querying w/ Cursor \(self.raceRecords.count)\n"))
                self.queryRaceStats(cursor: cursor)
            } else {
                self.textView.textStorage?.append(NSAttributedString(string: "Got All Race Stats\n"))
                self.processRaceStats()
            }
        }
    }

    private func queryRaceStats(cursor: CKQueryOperation.Cursor) {
        let queryOperation = CKQueryOperation(cursor: cursor)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = { record in
            self.raceRecords.append(record)
        }

        queryOperation.queryCompletionBlock = queryRaceCompleted(cursor:error:)
        publicDB.add(queryOperation)
    }

    // MARK: - Processing

    private func processRaceStats() {
        let keys = [
            "Links",
            "TotalPlayerTime",
            "PlayerCount",
            "URL",
            "CreatedAt"
        ]

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "WKRRaceState-" + Date().description
        panel.beginSheetModal(for: self.view.window!) { _ in
            guard let url = panel.url else { return }

            try? FileManager.default.createDirectory(at: url,
                                                withIntermediateDirectories: false,
                                                attributes: nil)

            var csvString = ""
            for key in keys {
                csvString += key + ","
            }
            csvString += "\n"
            for (index, record) in self.raceRecords.enumerated() {
                for key in keys {
                    if key == "URL", let assetURL = (record.object(forKey: "CSV") as? CKAsset)?.fileURL {
                        let fileURL = url.appendingPathComponent("\(index).csv")
                        try? FileManager.default.copyItem(at: assetURL, to: fileURL)
                        csvString += "\(fileURL)"
                    } else if let object = record.object(forKey: key) {
                        csvString += "\(object)"
                    } else if key == "CreatedAt", let date = record.creationDate {
                        csvString += "\(date)"
                    }
                    csvString += ","
                }
                csvString += "\n"
            }
            try? csvString.write(to: url.appendingPathComponent("Overview.csv"), atomically: false, encoding: .utf8)

        }

    }
}
