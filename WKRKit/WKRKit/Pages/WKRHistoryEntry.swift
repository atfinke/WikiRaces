//
//  WKRHistoryEntry.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRHistoryEntry: Codable {

    // MARK: - Properties

    public let page: WKRPage
    public let linkHere: Bool
    public private(set) var duration: Int?

    // MARK: - Initialization

    init(page: WKRPage, linkHere: Bool, duration: Int? = nil) {
        self.page = page
        self.linkHere = linkHere
        self.duration = duration
    }

    // MARK: - Duration

    mutating func set(duration: Int) {
        self.duration = duration
    }

}

extension WKRHistoryEntry: Equatable {

    // MARK: - Equatable

    //swiftlint:disable:next operator_whitespace
    public static func ==(lhs: WKRHistoryEntry, rhs: WKRHistoryEntry) -> Bool {
        guard lhs.page == rhs.page else {
            return false
        }
        if let lhsDuration = lhs.duration, let rhsDuration = rhs.duration {
            return lhsDuration == rhsDuration
        } else {
            return lhs.duration == nil && rhs.duration == nil
        }
    }

}
