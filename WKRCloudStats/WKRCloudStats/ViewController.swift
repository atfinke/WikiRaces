//
//  ViewController.swift
//  WKRCloudStats
//
//  Created by Andrew Finke on 10/11/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Cocoa
import CloudKit

class ViewController: NSViewController {

    // MARK: - Properties

    @IBOutlet private var textView: NSTextView!

    private var records = [CKRecord]()
    private let publicDB = CKContainer(identifier: "iCloud.com.andrewfinke.wikiraces").publicCloudDatabase

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.textStorage?.append(NSAttributedString(string: "Querying Stats\n"))
        queryStats()
    }

    func processResults() {
        let keys = [
            "CustomName",
            "DeviceName",
            "GCAlias",
            "Points",
            "Races",
            "Pages",
            "FastestTime",
            "TotalTime",
            "CreatedAt",
            "ModifiedAt"
        ]

        var csvString = ""
        for key in keys {
            csvString += key + ","
        }
        csvString += "\n"
        for record in records {
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

    // MARK: - CloudKit Querying

    private func queryStats() {
        let query = CKQuery(recordType: "UserStats", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let queryOperation = CKQueryOperation(query: query)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = { record in
            self.records.append(record)
        }

        queryOperation.queryCompletionBlock = { cursor, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.textView.textStorage?.append(NSAttributedString(string: "Error: \(error)\n"))
                } else if let cursor = cursor {
                    self.textView.textStorage?.append(NSAttributedString(string: "Querying w/ Cursor\n"))
                    self.queryStats(cursor: cursor)
                } else {
                    self.textView.textStorage?.append(NSAttributedString(string: "Got All Stats\n"))
                    self.processResults()
                }
            }
        }
        publicDB.add(queryOperation)
    }

    private func queryStats(cursor: CKQueryCursor) {
        let queryOperation = CKQueryOperation(cursor: cursor)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = { record in
            self.records.append(record)
        }

        queryOperation.queryCompletionBlock = { cursor, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.textView.textStorage?.append(NSAttributedString(string: "Error: \(error)\n"))
                } else if let cursor = cursor {
                    self.textView.textStorage?.append(NSAttributedString(string: "Querying w/ Cursor\n"))
                    self.queryStats(cursor: cursor)
                } else {
                    self.textView.textStorage?.append(NSAttributedString(string: "Got All Stats\n"))
                    self.processResults()
                }
            }
        }
        publicDB.add(queryOperation)
    }

}
