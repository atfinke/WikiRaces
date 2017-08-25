//
//  WKRPage.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRPage: Codable {

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
        let charactersToRemove = WKRRaceConstants.pageTitleCharactersToRemove
        if charactersToRemove > 0 && title.characters.count > charactersToRemove {
            let index = title.index(title.endIndex, offsetBy: -charactersToRemove)
            return title[..<index].capitalized
        } else {
            return title.replacingOccurrences(of: WKRRaceConstants.pageTitleStringToReplace, with: "").capitalized
        }
    }

}

extension WKRPage: Hashable, Equatable {

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
