//
//  WKRVoteInfo.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRVoteInfo: Codable, Equatable {

    // MARK: - Properties

    private let pages: [WKRPage]
    private var playerVotes = [WKRPlayerProfile: WKRPage]()

    public var pageCount: Int {
        return pages.count
    }

    // MARK: - Initialization

    internal init(pages: [WKRPage]) {
        let sortedPages = pages.sorted { (pageOne, pageTwo) -> Bool in
            return pageOne.title ?? "" < pageTwo.title ?? ""
        }
        self.pages = sortedPages
    }

    // MARK: - Helpers

    internal mutating func player(_ profile: WKRPlayerProfile, votedFor page: WKRPage) {
        playerVotes[profile] = page
    }

    internal func selectFinalPage() -> WKRPage? {
        var votes = [WKRPage: Int]()
        pages.forEach { votes[$0] = 0 }

        for page in Array(playerVotes.values) {
            let pageVotes = votes[page] ?? 0
            votes[page] = pageVotes + 1
        }

        var pagesWithMostVotes = [WKRPage]()
        var mostVotes = 0

        for (page, votes) in votes {
            if votes > mostVotes {
                pagesWithMostVotes = [page]
                mostVotes = votes
            } else if votes == mostVotes {
                pagesWithMostVotes.append(page)
            }
        }

        return pagesWithMostVotes.randomElement
    }

    // MARK: - Public Accessors

    public func page(for index: Int) -> (page: WKRPage, votes: Int)? {
        guard index < pages.count else { return nil }

        let page = pages[index]
        let votes = Array(playerVotes.values).filter({ $0 == page }).count

        return (page, votes)
    }

    public func index(of page: WKRPage) -> Int? {
        return pages.index(of: page)
    }

}
