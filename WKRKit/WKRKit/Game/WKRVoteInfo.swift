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
            return pageOne.title?.lowercased() ?? "" < pageTwo.title?.lowercased() ?? ""
        }
        self.pages = sortedPages
    }

    // MARK: - Helpers

    internal mutating func player(_ profile: WKRPlayerProfile, votedFor page: WKRPage) {
        playerVotes[profile] = page
    }

    internal func selectFinalPage(with weights: [WKRPlayerProfile: Int]) -> (WKRPage?, WKRLogEvent?) {
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

        var logEvent: WKRLogEvent?
        let totalPoints = Double(weights.values.reduce(0, +))
        let lowestScoringPlayers = weights.sorted(by: { $0.value < $1.value })

        // 1. Make sure there is a tie
        // 2. Make sure a few points have been given
        // 3. Make sure we have a lowest player
        // 4. Make sure player voted
        // 5. Make sure player voted for article with most/tied amount of votes
        if pagesWithMostVotes.count > 1,
            totalPoints > 4,
            lowestScoringPlayers.count > 1,
            let player = lowestScoringPlayers.first,
            let page = playerVotes[player.key],
            pagesWithMostVotes.contains(page) {

            let lowestScore = player.value
            let secondLowestScore = lowestScoringPlayers[1].value
            let diff = Double(secondLowestScore) - Double(lowestScore)
            let extraChance: Double
            if diff < 2 {
                extraChance = 0
            } else  {
                extraChance = min((diff - 2) * 0.2, 0.8)
            }

            let totalChance = extraChance + (1 - extraChance) * 0.5
            var attributes: [String: Any] = [
                "TiedCount": pagesWithMostVotes.count,
                "Chance": totalChance,
                "RawPointDiff": Int(diff)
            ]

            if Double.random(in: 0..<1) <= extraChance {
                attributes["BrokeTie"] = 1
                return (page, WKRLogEvent(type: .votingArticlesWeightedTiebreak,
                                          attributes: attributes))
            } else {
                attributes["BrokeTie"] = 0
                logEvent = WKRLogEvent(type: .votingArticlesWeightedTiebreak,
                                       attributes: attributes)
            }
        }

        return (pagesWithMostVotes.randomElement, logEvent)
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
