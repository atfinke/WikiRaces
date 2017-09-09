//
//  WKRPage.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRPage: Codable, Hashable, Equatable {

    // MARK: - Properties

    public let title: String?
    internal let url: URL

    // MARK: - Initialization

    public init(title: String?, url: URL) {
        self.title = WKRPage.formattedTitle(for: title)
        self.url = url
    }

    // MARK: - Helpers

    /// Removes extra characters in page title ("Wikipedia - Apple Inc." -> "Apple Inc.")
    private static func formattedTitle(for title: String?) -> String? {
        guard let title = title else { return nil }

        func smartCapitalize(_ title: String) -> String {
            // I can't stand Iphone / Os X
            if title.first == "i" {
                return title
            } else if title.contains("OS X") || title.contains("R2-D2") || title.contains("C-3PO") {
                return title
            } else {
                return title.capitalized
            }
        }
        let charactersToRemove = WKRKitConstants.pageTitleCharactersToRemove
        if charactersToRemove > 0 && title.characters.count > charactersToRemove {
            let index = title.index(title.endIndex, offsetBy: -charactersToRemove)
            let clippedTitle = title[..<index].capitalized
            return smartCapitalize(clippedTitle)
        } else {
            return smartCapitalize(title.replacingOccurrences(of: WKRKitConstants.pageTitleStringToReplace, with: ""))
        }
    }

    // MARK: - Hashable

    public var hashValue: Int {
        return url.hashValue
    }

    // MARK: - Equatable

    //swiftlint:disable:next operator_whitespace
    public static func ==(lhs: WKRPage, rhs: WKRPage) -> Bool {
        return lhs.title == rhs.title && lhs.url == rhs.url
    }
}
