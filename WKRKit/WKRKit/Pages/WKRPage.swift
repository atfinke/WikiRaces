//
//  WKRPage.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

/// A Wikipedia page
public struct WKRPage: Codable, Hashable, Equatable {

    // MARK: - Properties

    // The title of the page
    public let title: String?
    // The url of the page
    public let url: URL

    // should be `let`, but that would break backwards compatibility
    internal var path: String {
        return url.absoluteString.replacingOccurrences(of: "https://en.m.wikipedia.org/wiki", with: "")
    }

    // MARK: - Initialization

    /// Creates a WKRPage object
    ///
    /// - Parameters:
    ///   - title: The title of the page
    ///   - url: The url of the page
    public init(title: String?, url: URL) {
        self.title = WKRPage.formattedTitle(for: title)
        self.url = url
    }

    // MARK: - Helpers

    /// Removes extra characters in page title ("Wikipedia - Apple Inc." -> "Apple Inc.")
    private static func formattedTitle(for title: String?) -> String? {
        guard let title = title else { return nil }

        func smartFormat(_ title: String) -> String {
            return title.replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&apos;", with: "'")
                .replacingOccurrences(of: "&quot;", with: "\"")
        }

        // charactersToRemove is a fallback if simply replacing the "Wikipedia - " fails one day.
        let charactersToRemove = WKRKitConstants.current.pageTitleCharactersToRemove
        if charactersToRemove > 0 && title.count > charactersToRemove {
            // Again, will only be used if the constants plist
            // is updated one day to use raw character replacment instead of a string.
            let index = title.index(title.endIndex, offsetBy: -charactersToRemove)
            let clippedTitle = title[..<index]
            return smartFormat(String(clippedTitle))
        } else {
            // The expected path
            let title = title.replacingOccurrences(of: WKRKitConstants.current.pageTitleStringToReplace, with: "")
            return smartFormat(title)
        }
    }

}
