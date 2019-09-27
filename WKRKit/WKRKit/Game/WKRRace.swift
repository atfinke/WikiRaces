//
//  WKRRace.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

internal struct WKRRace {

    // MARK: - Properties

    private let isSolo: Bool

    /// The race's bonus points
    internal var bonusPoints = 0
    /// The end page for the race
    private let finalPage: WKRPage
    /// Fetches all the links that link to the page. Torn down at the end of the race.
    internal var linkedPagesFetcher: WKRLinkedPagesFetcher? = WKRLinkedPagesFetcher()
    /// The players that have participated in the race
    internal private(set) var players = [WKRPlayer]()

    // MARK: - Initialization

    internal init(config: WKRRaceConfig, isSolo: Bool) {
        self.isSolo = isSolo
        finalPage = config.endingPage
        linkedPagesFetcher?.start(for: finalPage)
    }

    // MARK: - Player Updates

    /// Update the race's players
    ///
    /// - Parameter player: The update player
    internal mutating func playerUpdated(_ player: WKRPlayer) {
        if let index = players.firstIndex(of: player) {
            players[index] = player
        } else {
            players.append(player)
        }
    }

    // MARK: - Pages

    /// Attributes for a Wikipedia page relating to the race. Used for detecting if the player found the page
    /// or is other players should show "X is close" message.
    ///
    /// - Parameter page: The page to check againts
    /// - Returns: Tuple with found page and link on page values.
    internal func attributes(for page: WKRPage) -> (foundPage: Bool, linkOnPage: Bool) {
        var adjustedURL = page.url

        // Adjust for links to sections
        if adjustedURL.absoluteString.contains("#") {
            let components = adjustedURL.absoluteString.components(separatedBy: "#")
            if components.count == 2, let newURL = URL(string: components[0]) {
                adjustedURL = newURL
            }
        }

        if page == finalPage {
            return (true, false)
        } else if adjustedURL == finalPage.url {
            return (true, false)
        } else if page.title == finalPage.title {
            return (true, false)
        } else if linkedPagesFetcher?.foundLinkOn(page) ?? false {
            return (false, true)
        }
        return (false, false)
    }

    // MARK: - End Race Helpers

    /// Calculates how my points each place should receive for the race. Every player that found the article
    /// gets points for how many players they did better then. All players also get the race bonus points
    /// if there are any.
    ///
    /// - Returns: Each player's points in a dictionary
    internal func calculatePoints() -> [WKRPlayerProfile: Int] {
        var times = [WKRPlayer: Int]()
        for player in players.filter({ $0.state == .foundPage }) {
            times[player] = player.raceHistory?.duration
        }

        var points = [WKRPlayerProfile: Int]()
        let positions = times.keys.sorted { (lhs, rhs) -> Bool in
            return times[lhs] ?? 0 < times[rhs] ?? 0
        }
        for (index, player) in positions.enumerated() {
            points[player.profile] = players.count - index - 1 + bonusPoints
        }
        return points
    }

    /// Check if the race should end. The race should end when there is one or less
    /// than one player still racing or when >= 3 players have finished
    ///
    /// - Returns: If the race should end
    internal func shouldEnd() -> Bool {
        if isSolo {
            return players.first?.state != .racing
        } else {
            return (players.filter({ $0.state == .racing }).count <= 1
                && players.filter({ $0.state != .connecting }).count > 1)
                || players.filter({ $0.state == .foundPage }).count >= WKRKitConstants.current.maxFoundPagePlayers
        }
    }

}
