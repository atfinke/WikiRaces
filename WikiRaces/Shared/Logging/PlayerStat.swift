//
//  PlayerStat.swift
//  WikiRaces
//
//  Created by Andrew Finke on 3/6/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Foundation

enum PlayerStat: String, CaseIterable {
    case average

    case mpcVotes
    case mpcHelp
    case mpcPoints
    case mpcPages
    // seconds
    case mpcFastestTime
    // minutes
    case mpcTotalTime
    case mpcRaces
    case mpcTotalPlayers
    case mpcUniquePlayers
    case mpcPressedJoin
    case mpcPressedHost
    case mpcRaceFinishFirst
    case mpcRaceFinishSecond
    case mpcRaceFinishThird
    case mpcRaceDNF

    case gkVotes
    case gkHelp
    case gkPoints
    case gkPages
    case gkFastestTime
    case gkTotalTime
    case gkRaces
    case gkTotalPlayers
    case gkUniquePlayers
    case gkPressedJoin
    case gkInvitedToMatch
    case gkConnectedToMatch
    case gkRaceFinishFirst
    case gkRaceFinishSecond
    case gkRaceFinishThird
    case gkRaceDNF

    case soloVotes
    case soloHelp
    case soloPages
    case soloFastestTime
    case soloTotalTime
    case soloRaces
    case soloPressedHost

    case pointsScrolled
    case displayedMedals

    #warning("remove for release")
    case bugHitCase1
    case bugHitCase2
    case bugHitCase3
    case bugHitCase4
    case bugHitCase5
    case bugHitCase6
    case bugHitCase7
    case bugHitCase8

    static var numericHighStats: [PlayerStat] = [
        .mpcVotes,
        .mpcHelp,
        .mpcPoints,
        .mpcPages,
        .mpcTotalTime,
        .mpcRaces,
        .mpcPressedJoin,
        .mpcPressedHost,
        .mpcRaceFinishFirst,
        .mpcRaceFinishSecond,
        .mpcRaceFinishThird,
        .mpcRaceDNF,

        .gkVotes,
        .gkHelp,
        .gkPoints,
        .gkPages,
        .gkTotalTime,
        .gkRaces,
        .gkPressedJoin,
        .gkInvitedToMatch,
        .gkConnectedToMatch,
        .gkRaceFinishFirst,
        .gkRaceFinishSecond,
        .gkRaceFinishThird,
        .gkRaceDNF,

        .soloVotes,
        .soloHelp,
        .soloPages,
        .soloTotalTime,
        .soloRaces,
        .soloPressedHost,

        .pointsScrolled,
        .displayedMedals
    ]

    static var numericLowStats: [PlayerStat] = [
        .mpcFastestTime,
        .gkFastestTime,
        .soloFastestTime
    ]

    var key: String {
        // legacy keys
        switch self {
        case .mpcTotalPlayers:  return "WKRStat-totalPlayers"
        case .mpcUniquePlayers: return "WKRStat-uniquePlayers"
        case .mpcPoints:        return "WKRStat-points"
        case .mpcPages:         return "WKRStat-pages"
        case .mpcFastestTime:   return "WKRStat-fastestTime"
        case .mpcTotalTime:     return "WKRStat-totalTime"
        case .mpcRaces:         return "WKRStat-races"
        default:                return "WKRStat-" + self.rawValue
        }
    }

    func value() -> Double {
        if self == .average {
            let races = PlayerStat.mpcPoints.value() + PlayerStat.gkPoints.value()
            let points = PlayerStat.mpcRaces.value() + PlayerStat.gkRaces.value()
            let value = races / points
            return value.isNaN ? 0.0 : value
        } else {
            return UserDefaults.standard.double(forKey: key)
        }
    }

    func increment(by value: Double = 1) {
        let newValue = self.value() + value
        UserDefaults.standard.set(newValue, forKey: key)
    }

}
