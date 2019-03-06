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

    internal let pages: [WKRPage]
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

    internal func selectFinalPage(with weights: [WKRPlayerProfile: Int]) -> WKRPage? {
        var votes = [WKRPage: Int]()
        pages.forEach { votes[$0] = 0 }

        for page in playerVotes.values {
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

        let totalPoints = Double(weights.values.reduce(0, +))
        let playerWithLowestScore = weights
            .sorted(by: { $0.value < $1.value })
            .first

        // 1. Make sure a few points have been given
        // 2. Make sure we have a lowest player
        // 3. Make sure player voted
        // 4. Make sure player voted for article with most/tied amount of votes
        if totalPoints > 4,
            let player = playerWithLowestScore,
            let page = playerVotes[player.key],
            pagesWithMostVotes.contains(page) {

            /*
             Example Scenarios:
             player w/ least points (plp) = 5
             total points = 25
             => if rand (0..<1) > 5/25 (0.2) => use the player's vote to break the tie (80% chance)

             plp = 10, total points = 25
             => ... 10/25 (0.4) => (60% chance)

             plp = 15, total points = 30
             => ... 15/30 (0.5) => (50% chance)

             + never > 90% chance
            */
            let inversePercentChance = max(Double(player.value) / totalPoints, 0.1)
            if Double.random(in: 0..<1) > inversePercentChance {
                return page
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
        return pages.firstIndex(of: page)
    }

}
