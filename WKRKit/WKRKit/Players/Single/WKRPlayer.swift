//
//  WKRPlayer.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WKRUIKit

final public class WKRPlayer: Codable, Hashable {

    // MARK: - Properties [Must not break]

    internal let isHost: Bool

    internal var hasReceivedPointsForCurrentRace = false

    public internal(set) var raceHistory: WKRHistory?
    public internal(set) var state: WKRPlayerState = .connecting

    public let profile: WKRPlayerProfile
    public var name: String {
        return profile.name
    }

    // MARK: - Stat Properties

    public private(set) var stats = WKRPlayerRaceStats()

    // MARK: - Initialization

    init(profile: WKRPlayerProfile, isHost: Bool) {
        self.isHost = isHost
        self.profile = profile
    }

    // MARK: - Race Actions

    func startedNewRace(on page: WKRPage) {
        state = .racing
        raceHistory = WKRHistory(firstPage: page)
        stats.reset()
    }

    func nowViewing(page: WKRPage, linkHere: Bool) {
        raceHistory?.append(page, linkHere: linkHere)
    }

    func finishedViewingLastPage(pixelsScrolled: Int) {
        raceHistory?.finishedViewingLastPage()
        stats.update(history: raceHistory, state: state, pixels: pixelsScrolled)
    }

    func neededHelp() {
        stats.neededHelp()
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        return profile.hash(into: &hasher)
    }

    public static func ==(lhs: WKRPlayer, rhs: WKRPlayer) -> Bool {
        return lhs.profile == rhs.profile
    }

}
