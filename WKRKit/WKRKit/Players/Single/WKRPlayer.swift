//
//  WKRPlayer.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

public class WKRPlayer: Codable, Hashable {

    // MARK: - Properties

    internal let isHost: Bool
    internal var shouldGetPoints = false

    public var raceHistory: WKRHistory?
    public var state: WKRPlayerState = .connecting

    public let profile: WKRPlayerProfile
    public var name: String {
        return profile.name
    }

    // MARK: - Initialization

    init(profile: WKRPlayerProfile, isHost: Bool) {
        self.isHost = isHost
        self.profile = profile
    }

    // MARK: - Race Actions

    func startedNewRace(on page: WKRPage) {
        state = .racing
        raceHistory = WKRHistory(firstPage: page)
    }

    func nowViewing(page: WKRPage, linkHere: Bool) {
        raceHistory?.append(page, linkHere: linkHere)
    }

    func finishedViewingLastPage() {
        raceHistory?.finishedViewingLastPage()
    }

    // MARK: - Hashable

    public var hashValue: Int {
        return profile.playerID.hashValue
    }

    //swiftlint:disable:next operator_whitespace
    public static func ==(lhs: WKRPlayer, rhs: WKRPlayer) -> Bool {
        return lhs.profile == rhs.profile
    }

}
