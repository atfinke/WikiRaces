//
//  WKRGameSettings.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/3/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

public class WKRGameSettings: Codable {

    // MARK: - Types -

    public enum StartPage {
        case random
        case custom(WKRPage)

        public var isStandard: Bool {
            switch self {
            case .random:
                return true
            default:
                return false
            }
        }
    }

    public enum EndPage {
        case curatedVoting
        case randomVoting
        case custom(WKRPage)

        public var isStandard: Bool {
            switch self {
            case .curatedVoting:
                return true
            default:
                return false
            }
        }
    }

    public enum BannedPage {
        case portal
        case custom(WKRPage)
    }

    public struct Notifications: Codable {
        public let neededHelp: Bool
        public let linkOnPage: Bool
        public let missedLink: Bool
        public let isOnUSA: Bool
        public let isOnSamePage: Bool

        public var isStandard: Bool {
            return neededHelp && linkOnPage && missedLink && isOnUSA && isOnSamePage
        }

        public init(neededHelp: Bool, linkOnPage: Bool, missedTheLink: Bool, isOnUSA: Bool, isOnSamePage: Bool) {
            self.neededHelp = neededHelp
            self.linkOnPage = linkOnPage
            self.missedLink = missedTheLink
            self.isOnUSA = isOnUSA
            self.isOnSamePage = isOnSamePage
        }
    }

    public struct Points: Codable {
        public let bonusPointReward: Int
        public let bonusPointsInterval: Double

        public var isStandard: Bool {
            return bonusPointsInterval == WKRKitConstants.current.bonusPointsInterval && bonusPointReward == WKRKitConstants.current.bonusPointReward
        }

        public init(bonusPointReward: Int, bonusPointsInterval: Double) {
            self.bonusPointReward = bonusPointReward
            self.bonusPointsInterval = bonusPointsInterval
        }
    }

    public struct Timing: Codable {
        public let votingTime: Int
        public let resultsTime: Int

        public var isStandard: Bool {
            return votingTime == WKRRaceDurationConstants.votingState && resultsTime == WKRRaceDurationConstants.resultsState
        }

        public init(votingTime: Int, resultsTime: Int) {
            self.votingTime = votingTime
            self.resultsTime = resultsTime
        }
    }

    public struct Other: Codable {
        public let isHelpEnabled: Bool

        public var isStandard: Bool {
            return isHelpEnabled
        }

        public init(isHelpEnabled: Bool) {
            self.isHelpEnabled = isHelpEnabled
        }
    }

    public struct Language: Codable {
        public let code: String

        public var isStandard: Bool {
            return code == "en"
        }

        public init(code: String) {
            self.code = code
        }
    }

    // MARK: - Properties -

    public var isCustom: Bool {
        if notifications.isStandard
            && points.isStandard
            && timing.isStandard
            && other.isStandard
            && startPage.isStandard
            && endPage.isStandard
            && language.isStandard,
            bannedPages.count == 1,
            case .portal = bannedPages[0] {
            return false
        } else {
            return true
        }
    }

    public var startPage: StartPage = .random
    public var endPage: EndPage = .curatedVoting
    public var bannedPages: [BannedPage] = [.portal]

    public var notifications = Notifications(
        neededHelp: true,
        linkOnPage: true,
        missedTheLink: true,
        isOnUSA: true,
        isOnSamePage: true)

    public var points = Points(bonusPointReward: WKRKitConstants.current.bonusPointReward, bonusPointsInterval: WKRKitConstants.current.bonusPointsInterval)
    public var timing = Timing(votingTime: WKRRaceDurationConstants.votingState, resultsTime: WKRRaceDurationConstants.resultsState)
    public var other = Other(isHelpEnabled: true)
    public var language = Language(code: "en")

    public func reset() {
        startPage = .random
        endPage = .curatedVoting
        bannedPages = [.portal]

        notifications = Notifications(
            neededHelp: true,
            linkOnPage: true,
            missedTheLink: true,
            isOnUSA: true,
            isOnSamePage: true)

        points = Points(bonusPointReward: WKRKitConstants.current.bonusPointReward, bonusPointsInterval: WKRKitConstants.current.bonusPointsInterval)
        timing = Timing(votingTime: WKRRaceDurationConstants.votingState, resultsTime: WKRRaceDurationConstants.resultsState)
        other = Other(isHelpEnabled: true)
    }

    public init() {}
}
