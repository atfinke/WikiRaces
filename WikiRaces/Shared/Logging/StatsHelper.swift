//
//  StatsHelper.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/31/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import CloudKit
import GameKit
import StoreKit

import WKRKit

//swiftlint:disable:next type_body_length
internal class StatsHelper {

    // MARK: - Types

    enum Stat: String {
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

        case soloVotes
        case soloHelp
        case soloPages
        case soloTotalTime
        case soloRaces
        case soloPressedHost

        case pointsScrolled

        static var numericHighStats: [Stat] = [
            .average,

            .mpcVotes,
            .mpcHelp,
            .mpcPoints,
            .mpcPages,
            .mpcTotalTime,
            .mpcRaces,
            .mpcPressedJoin,
            .mpcPressedHost,

            .gkVotes,
            .gkHelp,
            .gkPoints,
            .gkPages,
            .gkTotalTime,
            .gkRaces,
            .gkPressedJoin,
            .gkInvitedToMatch,
            .gkConnectedToMatch,

            .soloVotes,
            .soloHelp,
            .soloPages,
            .soloTotalTime,
            .soloRaces,
            .soloPressedHost,

            .pointsScrolled
        ]

        static var numericLowStats: [Stat] = [
            .mpcFastestTime,
            .gkFastestTime
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
    }

    enum RaceType: Int {
        case mpc = 1, gameKit = 2, solo = 3, other = 10

        init?(_ config: WKRPeerNetworkConfig) {
            switch config {
            case .solo:
                self = .solo
            case .gameKit:
                self = .gameKit
            case .mpc:
                self = .mpc
            default :
                return nil
            }
        }
    }

    // MARK: - Properties

    static let shared = StatsHelper()

    var keyStatsUpdated: ((_ points: Double, _ races: Double, _ average: Double) -> Void)?

    private let defaults = UserDefaults.standard
    private let keyValueStore = NSUbiquitousKeyValueStore.default

    // MARK: - Computed Properties

    var points: Double {
        return statValue(for: .mpcPoints) + statValue(for: .gkPoints)
    }

    var races: Double {
        return statValue(for: .mpcRaces) + statValue(for: .gkRaces)
    }

    var pages: Double {
        return statValue(for: .mpcPages) + statValue(for: .gkPages)
    }

    var totalTime: Double {
        return statValue(for: .mpcTotalTime) + statValue(for: .gkTotalTime)
    }

    var fastestTime: Double {
        let mpcTime = statValue(for: .mpcFastestTime)
        if mpcTime == 0 {
            return statValue(for: .gkFastestTime)
        } else {
            let gkTime = statValue(for: .gkFastestTime)
            if gkTime == 0 {
                return mpcTime
            } else if gkTime < mpcTime {
                return gkTime
            } else {
                return mpcTime
            }
        }
    }

    // MARK: - Initalization

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Helpers

    func start() {
        ubiquitousStoreSync()
        leaderboardSync()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyValueStoreChanged(_:)),
                                               name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: keyValueStore)

        keyValueStore.synchronize()
        playerDatabaseSync()
    }

    // MARK: - Set/Get Stats

    func statValue(for stat: Stat) -> Double {
        if stat == .average {
            let value = self.points / self.races
            return value.isNaN ? 0.0 : value
        } else {
            return defaults.double(forKey: stat.key)
        }
    }

    func increment(stat: Stat, by value: Double = 1) {
        let newValue = statValue(for: stat) + value
        defaults.set(newValue, forKey: stat.key)
    }

    func viewedPage(raceType: RaceType) {
        var stat: Stat
        switch raceType {
        case .mpc:
            stat = Stat.mpcPages
        case .gameKit:
            stat = Stat.gkPages
        case .solo:
            stat = Stat.soloPages
        case .other:
            return
        }
        increment(stat: stat)
    }

    func connected(to players: [String], raceType: RaceType) {
        var playersKey = ""
        var uniqueStat = Stat.mpcUniquePlayers
        var totalStat = Stat.mpcTotalPlayers
        switch raceType {
        case .mpc:
            playersKey = "PlayersArray"
            uniqueStat = Stat.mpcUniquePlayers
            totalStat = Stat.mpcTotalPlayers
        case .gameKit:
            playersKey = "GKPlayersArray"
            uniqueStat = Stat.gkUniquePlayers
            totalStat = Stat.gkTotalPlayers
        default:
            return
        }

        var existingPlayers = defaults.stringArray(forKey: playersKey) ?? []
        existingPlayers += players
        defaults.set(existingPlayers, forKey: playersKey)
        syncPlayerNamesStat(raceType: raceType)

        let uniquePlayers = Array(Set(existingPlayers)).count
        let totalPlayers = existingPlayers.count

        defaults.set(uniquePlayers, forKey: uniqueStat.key)
        defaults.set(totalPlayers, forKey: totalStat.key)

        let mpcUniquePlayers = Int(statValue(for: .mpcUniquePlayers))
        let mpcTotalPlayers = Int(statValue(for: .mpcTotalPlayers))
        let gkUniquePlayers = Int(statValue(for: .gkUniquePlayers))
        let gkTotalPlayers = Int(statValue(for: .gkTotalPlayers))

        PlayerDatabaseMetrics.shared.log(event: .players(mpcUnique: mpcUniquePlayers,
                                                         mpcTotal: mpcTotalPlayers,
                                                         gkUnique: gkUniquePlayers,
                                                         gkTotal: gkTotalPlayers))

        ubiquitousStoreSync()
    }

    //swiftlint:disable:next function_body_length
    func completedRace(type: RaceType, points: Int, timeRaced: Int) {
        switch type {
        case .mpc:
            let newPoints = statValue(for: .mpcPoints) + Double(points)
            let newRaces = statValue(for: .mpcRaces) + 1
            let newTotalTime = statValue(for: .mpcTotalTime) + Double(timeRaced)

            defaults.set(newPoints, forKey: Stat.mpcPoints.key)
            defaults.set(newRaces, forKey: Stat.mpcRaces.key)
            defaults.set(newTotalTime, forKey: Stat.mpcTotalTime.key)

            // If found page, check for fastest completion time
            if points > 0 {
                let currentFastestTime = statValue(for: .mpcFastestTime)
                if currentFastestTime == 0 {
                    defaults.set(timeRaced, forKey: Stat.mpcFastestTime.key)
                } else if timeRaced < Int(currentFastestTime) {
                    defaults.set(timeRaced, forKey: Stat.mpcFastestTime.key)
                }

                SKStoreReviewController.shouldPromptForRating = true
            } else {
                SKStoreReviewController.shouldPromptForRating = false
            }
        case .gameKit:
            let newPoints = statValue(for: .gkPoints) + Double(points)
            let newRaces = statValue(for: .gkRaces) + 1
            let newTotalTime = statValue(for: .gkTotalTime) + Double(timeRaced)

            defaults.set(newPoints, forKey: Stat.gkPoints.key)
            defaults.set(newRaces, forKey: Stat.gkRaces.key)
            defaults.set(newTotalTime, forKey: Stat.gkTotalTime.key)

            // If found page, check for fastest completion time
            if points > 0 {
                let currentFastestTime = statValue(for: .gkFastestTime)
                if currentFastestTime == 0 {
                    defaults.set(timeRaced, forKey: Stat.gkFastestTime.key)
                } else if timeRaced < Int(currentFastestTime) {
                    defaults.set(timeRaced, forKey: Stat.gkFastestTime.key)
                }
                SKStoreReviewController.shouldPromptForRating = true
            } else {
                SKStoreReviewController.shouldPromptForRating = false
            }
        case .solo:
            let newSoloTotalTime = statValue(for: .soloTotalTime) + Double(timeRaced)
            let newSoloRaces = statValue(for: .soloRaces) + 1
            defaults.set(newSoloTotalTime, forKey: Stat.soloTotalTime.key)
            defaults.set(newSoloRaces, forKey: Stat.soloRaces.key)
            SKStoreReviewController.shouldPromptForRating = true
        case .other:
            break
        }

        ubiquitousStoreSync()
        leaderboardSync()
        playerDatabaseSync()
    }

    // MARK: - Syncing

    @objc
    private func keyValueStoreChanged(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
            let reasonForChange = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber  else {
                return
        }

        let reason = reasonForChange.intValue
        if reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange {
            for key in changedKeys {
                guard let stat = Stat(rawValue: key) else { return }
                self.sync(stat, key: key)
            }
        }

        leaderboardSync()
        playerDatabaseSync()
    }

    private func sync(_ stat: Stat, key: String) {
        if Stat.numericHighStats.contains(stat) {
            let deviceValue = defaults.double(forKey: key)
            let cloudValue = keyValueStore.double(forKey: key)
            if deviceValue > cloudValue {
                keyValueStore.set(deviceValue, forKey: key)
            } else if cloudValue > deviceValue {
                defaults.set(cloudValue, forKey: key)
            }
        } else if Stat.numericLowStats.contains(stat) {
            let deviceValue = defaults.double(forKey: stat.key)
            let cloudValue = keyValueStore.double(forKey: stat.key)
            if cloudValue < deviceValue && cloudValue != 0.0 {
                defaults.set(cloudValue, forKey: stat.key)
            } else if deviceValue != 0.0 {
                keyValueStore.set(deviceValue, forKey: stat.key)
            }
        } else if stat == .mpcTotalPlayers {
            syncPlayerNamesStat(raceType: .mpc)
        } else if stat == .gkTotalPlayers {
            syncPlayerNamesStat(raceType: .gameKit)
        }
    }

    private func ubiquitousStoreSync() {
        for stat in Stat.numericHighStats {
            let deviceValue = defaults.double(forKey: stat.key)
            let cloudValue = keyValueStore.double(forKey: stat.key)
            if deviceValue > cloudValue {
                keyValueStore.set(deviceValue, forKey: stat.key)
            } else if cloudValue > deviceValue {
                defaults.set(cloudValue, forKey: stat.key)
            }
        }

        for stat in Stat.numericLowStats {
            let deviceValue = defaults.double(forKey: stat.key)
            let cloudValue = keyValueStore.double(forKey: stat.key)
            if cloudValue < deviceValue && cloudValue != 0.0 {
                defaults.set(cloudValue, forKey: stat.key)
            } else if deviceValue != 0.0 {
                keyValueStore.set(deviceValue, forKey: stat.key)
            }
        }

        syncPlayerNamesStat(raceType: .mpc)
        syncPlayerNamesStat(raceType: .gameKit)
    }

    private func syncPlayerNamesStat(raceType: RaceType) {
        var stat = ""
        if raceType == .mpc {
            stat = "PlayersArray"
        } else if raceType == .gameKit {
            stat = "GKPlayersArray"
        } else {
            return
        }
        let deviceValue = defaults.array(forKey: stat) ?? []
        let cloudValue = keyValueStore.array(forKey: stat) ?? []
        if deviceValue.count < cloudValue.count {
            defaults.set(cloudValue, forKey: stat)
        } else if cloudValue.count < deviceValue.count {
            keyValueStore.set(deviceValue, forKey: stat)
        }
    }

    //swiftlint:disable:next function_body_length
    private func playerDatabaseSync() {
        let mpcVotes = statValue(for: .mpcVotes)
        let mpcHelp = statValue(for: .mpcHelp)
        let mpcPoints = statValue(for: .mpcPoints)
        let mpcFastestTime = statValue(for: .mpcFastestTime)
        let mpcTotalTime = statValue(for: .mpcTotalTime)
        let mpcPages = statValue(for: .mpcPages)
        let mpcRaces = statValue(for: .mpcRaces)
        let mpcPressedJoin = statValue(for: .mpcPressedJoin)
        let mpcPressedHost = statValue(for: .mpcPressedHost)

        let gkVotes = statValue(for: .gkVotes)
        let gkHelp = statValue(for: .gkHelp)
        let gkPoints = statValue(for: .gkPoints)
        let gkFastestTime = statValue(for: .gkFastestTime)
        let gkTotalTime = statValue(for: .gkTotalTime)
        let gkPages = statValue(for: .gkPages)
        let gkRaces = statValue(for: .gkRaces)
        let gkPressedJoin = statValue(for: .gkPressedJoin)
        let gkInvitedToMatch = statValue(for: .gkInvitedToMatch)
        let gkConnectedToMatch = statValue(for: .gkConnectedToMatch)

        let soloVotes = statValue(for: .soloVotes)
        let soloHelp = statValue(for: .soloHelp)
        let soloTotalTime = statValue(for: .soloTotalTime)
        let soloPages = statValue(for: .soloPages)
        let soloRaces = statValue(for: .soloRaces)
        let soloPressedHost = statValue(for: .soloPressedHost)

        let pointsScrolled = statValue(for: .pointsScrolled)

        keyStatsUpdated?(mpcPoints, mpcRaces, statValue(for: .average))

        let mpcStats = PlayerDatabaseMetrics.Event.mpcStatsUpdate(mpcVotes: Int(mpcVotes),
                                                                  mpcHelp: Int(mpcHelp),
                                                                  mpcPoints: Int(mpcPoints),
                                                                  mpcRaces: Int(mpcRaces),
                                                                  mpcFastestTime: Int(mpcFastestTime),
                                                                  mpcTotalTime: Int(mpcTotalTime),
                                                                  mpcPages: Int(mpcPages),
                                                                  mpcPressedJoin: Int(mpcPressedJoin),
                                                                  mpcPressedHost: Int(mpcPressedHost))
        PlayerDatabaseMetrics.shared.log(event: mpcStats)

        let gkStats = PlayerDatabaseMetrics.Event.gkStatsUpdate(gkVotes: Int(gkVotes),
                                                                gkHelp: Int(gkHelp),
                                                                gkPoints: Int(gkPoints),
                                                                gkRaces: Int(gkRaces),
                                                                gkFastestTime: Int(gkFastestTime),
                                                                gkTotalTime: Int(gkTotalTime),
                                                                gkPages: Int(gkPages),
                                                                gkPressedJoin: Int(gkPressedJoin),
                                                                gkInvitedToMatch: Int(gkInvitedToMatch),
                                                                gkConnectedToMatch: Int(gkConnectedToMatch))
        PlayerDatabaseMetrics.shared.log(event: gkStats)

        let soloStats = PlayerDatabaseMetrics.Event.soloStatsUpdate(soloVotes: Int(soloVotes),
                                                                    soloHelp: Int(soloHelp),
                                                                    soloRaces: Int(soloRaces),
                                                                    soloTotalTime: Int(soloTotalTime),
                                                                    soloPages: Int(soloPages),
                                                                    soloPressedHost: Int(soloPressedHost))
        PlayerDatabaseMetrics.shared.log(event: soloStats)

        PlayerDatabaseMetrics.shared.log(event: .pointsScrolled(Int(pointsScrolled)))
    }

    private func leaderboardSync() {
        guard GKLocalPlayer.local.isAuthenticated else {
            return
        }

        let points = self.points
        let races = self.races
        let average = statValue(for: .average)

        let totalTime = self.totalTime
        let fastestTime = self.fastestTime
        let pagesViewed = self.pages

        let pointsScore = GKScore(leaderboardIdentifier: "com.andrewfinke.wikiraces.points")
        pointsScore.value = Int64(points)

        let racesScore = GKScore(leaderboardIdentifier: "com.andrewfinke.wikiraces.races")
        racesScore.value = Int64(races)

        let totalTimeScore = GKScore(leaderboardIdentifier: "com.andrewfinke.wikiraces.totaltime")
        totalTimeScore.value = Int64(totalTime / 60)

        let pagesViewedScore = GKScore(leaderboardIdentifier: "com.andrewfinke.wikiraces.pages")
        pagesViewedScore.value = Int64(pagesViewed)

        var scores = [pointsScore, racesScore, totalTimeScore, totalTimeScore, pagesViewedScore]
        if races >= 5 {
            let averageScore = GKScore(leaderboardIdentifier: "com.andrewfinke.wikiraces.ppr")
            averageScore.value = Int64(average * 1_000)
            scores.append(averageScore)
        }
        if fastestTime > 0 {
            let fastestTimeScore = GKScore(leaderboardIdentifier: "com.andrewfinke.wikiraces.fastesttime")
            fastestTimeScore.value = Int64(fastestTime)
            scores.append(fastestTimeScore)
        }
        GKScore.report(scores, withCompletionHandler: nil)
    }
    //swiftlint:disable:next file_length
}
