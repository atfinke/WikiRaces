//
//  WKRPlayer.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public class WKRPlayer: Codable, Hashable {

    // MARK: - Properties [Must not break]

    internal let isHost: Bool

    // poorly named (needs to stay backwards compatible), indicating if time spent + points awarded for race
    internal var shouldGetPoints = false

    public internal(set) var raceHistory: WKRHistory?
    public internal(set) var state: WKRPlayerState = .connecting

    internal let profile: WKRPlayerProfile
    public var name: String {
        return profile.name
    }

    // MARK: - Stat Properties [Optional to be backwards compatible]

    public private(set) var stats: WKRPlayerRaceStats?
    internal private(set) var neededHelpCount: Int?
    internal private(set) var pixelsScrolled: Int?
    public var isCreator: Bool?

    // MARK: - Initialization

    init(profile: WKRPlayerProfile, isHost: Bool) {
        self.isHost = isHost
        self.profile = profile
    }

    // MARK: - Race Actions

    func startedNewRace(on page: WKRPage) {
        state = .racing
        raceHistory = WKRHistory(firstPage: page)
        neededHelpCount = 0
        pixelsScrolled = 0
        stats = WKRPlayerRaceStats(player: self)
    }

    func nowViewing(page: WKRPage, linkHere: Bool) {
        raceHistory?.append(page, linkHere: linkHere)
        stats = WKRPlayerRaceStats(player: self)
    }

    func finishedViewingLastPage(pixelsScrolled: Int) {
        raceHistory?.finishedViewingLastPage()
        self.pixelsScrolled = pixelsScrolled
    }

    func neededHelp() {
        neededHelpCount = (neededHelpCount ?? 0) + 1
        stats = WKRPlayerRaceStats(player: self)
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        return profile.playerID.hash(into: &hasher)
    }

    //swiftlint:disable:next operator_whitespace
    public static func ==(lhs: WKRPlayer, rhs: WKRPlayer) -> Bool {
        return lhs.profile == rhs.profile
    }

}
