//
//  WKRvotingState.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRVotingState: Codable, Equatable {

    // MARK: - Properties

    internal var pages: [WKRPage] {
        return Array(playerVotes.keys)
    }
    private var playerVotes = [WKRPage: [WKRPlayerProfile]]()

    // MARK: - Initialization

    internal init(pages: [WKRPage]) {
        pages.forEach { playerVotes[$0] = [] }
    }

    // MARK: - Helpers

    public mutating func player(_ profile: WKRPlayerProfile, votedFor page: WKRPage) {
        playerVotes.keys.forEach { page in
            guard let index = playerVotes[page]?.firstIndex(of: profile) else { return }
            playerVotes[page]?.remove(at: index)
        }
        playerVotes[page]?.append(profile)
    }

    internal func selectFinalPage(with weights: [WKRPlayerProfile: Int]) -> (WKRPage?, WKRLogEvent?) {
        var pagesWithMostVotes = [WKRPage]()
        var mostVotes = 0
        for (page, voters) in playerVotes {
            if voters.count > mostVotes {
                pagesWithMostVotes = [page]
                mostVotes = voters.count
            } else if voters.count == mostVotes {
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
            let page = pagesWithMostVotes.first(where: { playerVotes[$0]?.contains(player.key) ?? false }) {

            let lowestScore = player.value
            let secondLowestScore = lowestScoringPlayers[1].value
            let diff = Double(secondLowestScore) - Double(lowestScore)
            let extraChance: Double
            if diff < 2 {
                extraChance = 0
            } else {
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

    public var current: [(page: WKRPage, voters: [WKRPlayerProfile])] {
        let sortedPages = playerVotes.keys.sorted { (pageOne, pageTwo) -> Bool in
            return pageOne.title?.lowercased() ?? "" < pageTwo.title?.lowercased() ?? ""
        }

        return sortedPages.map { page in
            return (page, playerVotes[page] ?? [])
        }
    }

}
