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

        // 1. Make sure a few points have been given
        // 2. Make sure we have a lowest player
        // 3. Make sure player voted
        // 4. Make sure player voted for article with most/tied amount of votes
        if totalPoints > 4,
            lowestScoringPlayers.count > 1,
            let player = lowestScoringPlayers.first,
            let page = playerVotes[player.key],
            pagesWithMostVotes.contains(page) {

            /*
             P1 Points = player with lowest points
             P2 Points = player with next lowest points
             Break Tie Chance = chance that p1 will break the tie
             Total Chance = Probability p1 article choosen (break tie chance + random chance)
             - x way = x number of articles tied with most votes

             +-----------+-----------+------------------+----------------------+----------------------+
             | P1 Points | P2 Points | Break Tie Chance | Total Chance (2 way) | Total Chance (3 way) |
             +-----------+-----------+------------------+----------------------+----------------------+
             |     0...4 |        10 | 60%              | 80%                  | 73.2%                |
             |         5 |        10 | 50%              | 75%                  | 66.5%                |
             |         6 |        10 | 40%              | 70%                  | 59.8%                |
             |         7 |        10 | 30%              | 65%                  | 53.1%                |
             |         8 |        10 | 20%              | 60%                  | 46.4%                |
             |         9 |        10 | 10%              | 55%                  | 39.7%                |
             |        10 |        10 | 0%               | 50%                  | 33%                  |
             +-----------+-----------+------------------+----------------------+----------------------+
            */
            let nextLowestPoints = Double(lowestScoringPlayers[1].value)
            let inversePercentChance = max(Double(player.value) / nextLowestPoints, 0.4)

            var attributes: [String: Any] = [
                "TiedCount": pagesWithMostVotes.count,
                "Chance": 1.0 - inversePercentChance,
                "RawPointDiff": Int(nextLowestPoints) - player.value
            ]

            if Double.random(in: 0..<1) > inversePercentChance {
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
