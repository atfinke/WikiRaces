//
//  WKRPlayerRaceStats.swift
//  WKRKit
//
//  Created by Andrew Finke on 2/27/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRPlayerRaceStats: Codable, Equatable {

    // MARK: - Properties

    static let pixelFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private var statsDictionary = [String: String]()

    public var raw: [(key: String, value: String)] {
        return statsDictionary
            .map({ ($0.key, $0.value) })
            .sorted(by: { $0.0 < $1.0 })
    }

    init(player: WKRPlayer) {
//        statsDictionary["Links missed"] = linksMissed(player)
        statsDictionary["Average time per page"] = avergeTimeSpent(player)
        statsDictionary["Distance scrolled"] = "0 Pixels"
//
//        if let neededHelpCount = player.neededHelpCount {
////            statsDictionary["Needed help"] = neededHelpCount.description
//        }
        if let pointsScrolled = player.pointsScrolled,
            let formatted = WKRPlayerRaceStats.pixelFormatter.string(from: NSNumber(value: pointsScrolled)) {
            statsDictionary["Distance scrolled"] = formatted + " Pixels"
        }
    }

    func linksMissed(_ player: WKRPlayer) -> String {
        guard let history = player.raceHistory else { return "-" }
        let state = player.state

        var linkCount = history.entries.filter({ $0.linkHere }).count
        // on a page with the link
        if let lastLinkHere = history.entries.last?.linkHere,
            lastLinkHere,
            state == .racing {
            linkCount -= 1
        }
        // finished race, link on second to last page (last page is the destination)
        if state == .foundPage,
            history.entries.count > 2,
            history.entries[history.entries.count - 2].linkHere {
            linkCount -= 1
        }
        return linkCount.description
    }

    func avergeTimeSpent(_ player: WKRPlayer) -> String {
        guard let history = player.raceHistory,
            let duration = history.duration else { return "-" }
        var entriesCount = history.entries.count

        // viewing this page, don't count yet
        if history.entries.last?.duration == nil {
            entriesCount -= 1
        }
        if entriesCount == 0 {
            return "-"
        }
        let average = Int(round(Double(duration) / Double(entriesCount)))
        return WKRDurationFormatter.string(for: average) ?? "-"
    }
}
