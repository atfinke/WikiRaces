//
//  RaceSettings.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/3/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation
import WKRKit

class RaceSettings: Codable {

    // MARK: - Types -

    enum StartPage {
        case random
        case custom(WKRPage)

        var isStandard: Bool {
            switch self {
            case .random:
                return true
            default:
                return false
            }
        }
    }

    enum EndPage {
        case curatedVoting
        case randomVoting
        case custom(WKRPage)

        var isStandard: Bool {
            switch self {
            case .curatedVoting:
                return true
            default:
                return false
            }
        }
    }

    enum BannedPage {
        case portal
        case custom(WKRPage)
    }

    struct Notifications: Codable {
        let neededHelp: Bool
        let linkOnPage: Bool
        let missedTheLink: Bool
        let isOnUSA: Bool
        let isOnSamePage: Bool

        var isStandard: Bool {
            return neededHelp && linkOnPage && missedTheLink && isOnUSA && isOnSamePage
        }
    }

    struct Points: Codable {
        let bonusPointsReward: Int
        let bonusPointsInterval: Int

        var isStandard: Bool {
            return bonusPointsInterval == 30 && bonusPointsReward == 5
        }
    }

    struct Timing: Codable {
        let votingTime: Int
        let resultsTime: Int

        var isStandard: Bool {
            return votingTime == 15 && resultsTime == 60
        }
    }

    struct Other: Codable {
        let isHelpEnabled: Bool

        var isStandard: Bool {
            return isHelpEnabled
        }
    }

    // MARK: - Properties -

    var isEligibleForStats: Bool {
        if points.isStandard, case StartPage.random = startPage {
            return true
        } else {
            return false
        }
    }

    var isCustom: Bool {
        if notifications.isStandard
            && points.isStandard
            && timing.isStandard
            && other.isStandard,
            case StartPage.random = startPage,
            case EndPage.curatedVoting = endPage,
            bannedPages.count == 1,
            case .portal = bannedPages[0] {
            return false
        } else {
            return true
        }
    }

    var startPage: StartPage = .random
    var endPage: EndPage = .curatedVoting
    var bannedPages: [BannedPage] = [.portal]

    var notifications = Notifications(
        neededHelp: true,
        linkOnPage: true,
        missedTheLink: true,
        isOnUSA: true,
        isOnSamePage: true)

    var points = Points(bonusPointsReward: 5, bonusPointsInterval: 30)
    var timing = Timing(votingTime: 15, resultsTime: 60)
    var other = Other(isHelpEnabled: true)

    func reset() {
        startPage = .random
        endPage = .curatedVoting
        bannedPages = [.portal]

        notifications = Notifications(
            neededHelp: true,
            linkOnPage: true,
            missedTheLink: true,
            isOnUSA: true,
            isOnSamePage: true)

        points = Points(bonusPointsReward: 5, bonusPointsInterval: 30)
        timing = Timing(votingTime: 15, resultsTime: 60)
        other = Other(isHelpEnabled: true)
    }
}
