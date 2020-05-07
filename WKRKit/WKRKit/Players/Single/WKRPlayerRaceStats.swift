//
//  WKRPlayerRaceStats.swift
//  WKRKit
//
//  Created by Andrew Finke on 2/27/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Foundation

public class WKRPlayerRaceStats: Codable, Equatable {

    // MARK: - Properties

    static let pixelFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private var statsDictionary = [String: String]()
    private var helpNeeded = 0

    public var raw: [(key: String, value: String)] {
        return statsDictionary
            .map({ ($0.key, $0.value) })
            .sorted(by: { $0.0 < $1.0 })
    }

    // MARK: - Initalization -

    init() {
        reset()
    }

    func reset() {
        helpNeeded = 0
        update(history: nil, state: .connecting, pixels: 0)
        statsDictionary["Help needed"] = "0 Times"
    }

    func update(history: WKRHistory?, state: WKRPlayerState, pixels: Int) {
        statsDictionary["Links missed"] = linksMissed(history: history, state: state)
        statsDictionary["Average time per page"] = avergeTimeSpent(history: history)

        if let formatted = WKRPlayerRaceStats.pixelFormatter.string(from: NSNumber(value: pixels)) {
            statsDictionary["Distance scrolled"] = formatted + " Pixels"
        } else {
            statsDictionary["Distance scrolled"] = "0 Pixels"
        }
    }

    func neededHelp() {
        helpNeeded += 1
        statsDictionary["Help needed"] = "\(helpNeeded) Time" + (helpNeeded == 1 ? "" : "s")
    }

    // MARK: - Helpers -

    private func linksMissed(history: WKRHistory?, state: WKRPlayerState) -> String {
        guard let history = history else { return "0 Links" }

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
        return "\(linkCount) Link" + (linkCount == 1 ? "" : "s")
    }

    private func avergeTimeSpent(history: WKRHistory?) -> String {
        guard let history = history, let duration = history.duration else { return "-" }
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

    // MARK: - Equatable -

    public static func == (lhs: WKRPlayerRaceStats, rhs: WKRPlayerRaceStats) -> Bool {
        return lhs.statsDictionary == rhs.statsDictionary
    }

}
