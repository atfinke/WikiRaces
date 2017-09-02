//
//  WKRHistory.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRHistory: Codable, Equatable {

    // MARK: - Properties

    private var lastPageOpenTime: Date?
    public fileprivate(set) var entries = [WKRHistoryEntry]()

    internal var count: Int {
        return entries.count
    }

    public var duration: Int {
        if entries.count <= 1, entries.first?.duration == nil {
            return Int.max
        }
        return entries.flatMap { $0.duration }.reduce(0, +)
    }

    // MARK: - Initialization

    init(firstPage page: WKRPage) {
        append(page, linkHere: false)
    }

    // MARK: - Mutating

    mutating func append(_ page: WKRPage, linkHere: Bool) {
        guard page != entries.last?.page else { return }
        lastPageOpenTime = Date()
        entries.append(WKRHistoryEntry(page: page, linkHere: linkHere))
    }

    mutating func finishedViewingLastPage() {
        guard var entry = entries.last, let date = lastPageOpenTime else { return }
        entry.set(duration: Int(-date.timeIntervalSinceNow))
        entries[entries.count - 1] = entry
    }

    // MARK: - Equatable

    //swiftlint:disable:next operator_whitespace
    public static func ==(lhs: WKRHistory, rhs: WKRHistory) -> Bool {
        guard lhs.entries == rhs.entries else {
            return false
        }
        if let lhsDate = lhs.lastPageOpenTime, let rhsDate = rhs.lastPageOpenTime {
            return lhsDate == rhsDate
        } else {
            return lhs.lastPageOpenTime == nil && rhs.lastPageOpenTime == nil
        }
    }

}
