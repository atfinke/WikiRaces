//
//  WKRHistory.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

/// A player's Wikipedia history during a race
public struct WKRHistory: Codable, Equatable {

    // MARK: - Properties

    /// The time the player opened the last page
    private var lastPageOpenTime: Date
    /// The history entries
    public fileprivate(set) var entries = [WKRHistoryEntry]()
    /// The total time the player has been racing (not including page load times)
    public var duration: Int {
        if entries.first?.duration == nil {
            return Int.max
        }
        return entries.flatMap { $0.duration }.reduce(0, +)
    }

    // MARK: - Initialization

    /// Creates a WKRHistory object
    ///
    /// - Parameter page: The first page in the history
    init(firstPage page: WKRPage) {
        lastPageOpenTime = Date()

        let entry = WKRHistoryEntry(page: page, linkHere: false)
        entries.append(entry)
    }

    // MARK: - Mutating

    mutating func append(_ page: WKRPage, linkHere: Bool) {
        guard page != entries.last?.page else { return }
        lastPageOpenTime = Date()
        entries.append(WKRHistoryEntry(page: page, linkHere: linkHere))
    }

    mutating func finishedViewingLastPage() {
        guard var entry = entries.last else { fatalError() }
        entry.set(duration: Int(-lastPageOpenTime.timeIntervalSinceNow))
        entries[entries.count - 1] = entry
    }

    // MARK: - Equatable

    //swiftlint:disable:next operator_whitespace
    public static func ==(lhs: WKRHistory, rhs: WKRHistory) -> Bool {
        guard lhs.entries == rhs.entries else {
            return false
        }
        return lhs.lastPageOpenTime == rhs.lastPageOpenTime
    }

}
