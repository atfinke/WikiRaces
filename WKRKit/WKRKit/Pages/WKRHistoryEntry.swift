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
    public internal(set) var duration: Int?

    private let uuid: UUID

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

        self.uuid = UUID()
    }

}
