//
//  WKRHistoryEntry.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

/// A page the player has viewed in race
public struct WKRHistoryEntry: Codable, Equatable {

    // MARK: - Properties

    /// The page
    public let page: WKRPage
    /// If the link to the final page is on this page
    public let linkHere: Bool
    /// How long the player spent on the page (if not currently viewing)
    public private(set) var duration: Int?

    // MARK: - Initialization

    /// Creates a WKRHistoryEntry object
    ///
    /// - Parameters:
    ///   - page: The page
    ///   - linkHere: If the link to the final page is on this page
    ///   - duration: How long the player spent on the page (if not currently viewing)
    init(page: WKRPage, linkHere: Bool, duration: Int? = nil) {
        self.page = page
        self.linkHere = linkHere
        self.duration = duration
    }

    // MARK: - Duration

    /// Sets how long the player spent on the page
    ///
    /// - Parameter duration: The time the player spent on the page
    mutating func set(duration: Int) {
        self.duration = duration
    }

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
