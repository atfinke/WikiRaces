//
//  WKRActiveRace.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

struct WKRActiveRace {

    // MARK: - Properties

    private let finalPage: WKRPage
    private let linkedPagesFetcher = WKRLinkedPagesFetcher()

    internal private(set) var players = [WKRPlayer]()

    // MARK: - Initialization

    internal init(config: WKRRaceConfig) {
        finalPage = config.endingPage
        linkedPagesFetcher.start(for: finalPage)
    }

    // MARK: - Player Updates

    internal mutating func playerUpdated(_ player: WKRPlayer) {
        if let index = players.index(of: player) {
            players[index] = player
        } else {
            players.append(player)
        }
    }

    // MARK: - Pages

    internal func attributesFor(_ page: WKRPage) -> (foundPage: Bool, linkOnPage: Bool) {
        if page == finalPage {
            return (true, false)
        } else if page.url == finalPage.url {
            return (true, false)
        } else if page.title == finalPage.title {
            return (true, false)
        } else if linkedPagesFetcher.foundLinkOn(page) {
            return (false, true)
        }
        return (false, false)
    }

    // MARK: - End Race Helpers

    internal func calculatePoints() -> [WKRPlayerProfile: Int] {
        var times = [WKRPlayer: Int]()
        for player in players.filter({ $0.state == .foundPage }) {
            times[player] = player.raceHistory?.duration
        }

        var points = [WKRPlayerProfile: Int]()
        let positions = times.keys.sorted { (lhs, rhs) -> Bool in
            return times[lhs] ?? 0 < times[rhs] ?? 0
        }
        let bonusPoints = 0
        for (index, player) in positions.enumerated() {
            points[player.profile] = players.count - index - 1 + bonusPoints
        }
        return points
    }

    internal func shouldEnd() -> Bool {
        return players.filter({ $0.state == .racing}).count <= 1 && players.filter({ $0.state != .connecting}).count > 1
    }

}
