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

    enum RaceType: Int {
        case mpc = 1, gameKit = 2, solo = 3

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

    var combinedPoints: Double {
        return PlayerStat.mpcPoints.value() + PlayerStat.gkPoints.value()
    }

    var combinedRaces: Double {
        return PlayerStat.mpcRaces.value() + PlayerStat.gkRaces.value()
    }

    var combinedPages: Double {
        return PlayerStat.mpcPages.value() + PlayerStat.gkPages.value()
    }

    var combinedTotalTime: Double {
        return PlayerStat.mpcTotalTime.value() + PlayerStat.gkTotalTime.value()
    }

    var combinedFastestTime: Double {
        let mpcTime = PlayerStat .mpcFastestTime.value()
        if mpcTime == 0 {
            return PlayerStat.gkFastestTime.value()
        } else {
            let gkTime = PlayerStat.gkFastestTime.value()
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

    func viewedPage(raceType: RaceType) {
        var stat: PlayerStat
        switch raceType {
        case .mpc:
            stat = PlayerStat.mpcPages
        case .gameKit:
            stat = PlayerStat.gkPages
        case .solo:
            stat = PlayerStat.soloPages
        }
        stat.increment()
    }

    func connected(to players: [String], raceType: RaceType) {
        var playersKey = ""
        var uniqueStat = PlayerStat.mpcUniquePlayers
        var totalStat = PlayerStat.mpcTotalPlayers
        switch raceType {
        case .mpc:
            playersKey = "PlayersArray"
            uniqueStat = PlayerStat.mpcUniquePlayers
            totalStat = PlayerStat.mpcTotalPlayers
        case .gameKit:
            playersKey = "GKPlayersArray"
            uniqueStat = PlayerStat.gkUniquePlayers
            totalStat = PlayerStat.gkTotalPlayers
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

        logStatToMetric(.mpcUniquePlayers)
        logStatToMetric(.mpcTotalPlayers)
        logStatToMetric(.gkUniquePlayers)
        logStatToMetric(.gkTotalPlayers)

        ubiquitousStoreSync()
    }

    //swiftlint:disable:next function_body_length cyclomatic_complexity
    func completedRace(type: RaceType, points: Int, place: Int?, timeRaced: Int) {
        switch type {
        case .mpc:
            PlayerStat.mpcPoints.increment(by: Double(points))
            PlayerStat.mpcRaces.increment()
            PlayerStat.mpcTotalTime.increment(by: Double(timeRaced))

            if let place = place {
                if place == 1 {
                    PlayerStat.mpcRaceFinishFirst.increment()
                } else if place == 2 {
                    PlayerStat.mpcRaceFinishSecond.increment()
                } else if place == 3 {
                    PlayerStat.mpcRaceFinishThird.increment()
                }
            }

            // If found page, check for fastest completion time
            if points > 0 {
                let currentFastestTime = PlayerStat.mpcFastestTime.value()
                if currentFastestTime == 0 {
                    defaults.set(timeRaced, forKey: PlayerStat.mpcFastestTime.key)
                } else if timeRaced < Int(currentFastestTime) {
                    defaults.set(timeRaced, forKey: PlayerStat.mpcFastestTime.key)
                }

                SKStoreReviewController.shouldPromptForRating = true
            } else {
                SKStoreReviewController.shouldPromptForRating = false
            }
        case .gameKit:
            PlayerStat.gkPoints.increment(by: Double(points))
            PlayerStat.gkRaces.increment()
            PlayerStat.gkTotalTime.increment(by: Double(timeRaced))

            if let place = place {
                if place == 1 {
                    PlayerStat.gkRaceFinishFirst.increment()
                } else if place == 2 {
                    PlayerStat.gkRaceFinishSecond.increment()
                } else if place == 3 {
                    PlayerStat.gkRaceFinishThird.increment()
                }
            }

            // If found page, check for fastest completion time
            if points > 0 {
                let currentFastestTime = PlayerStat.gkFastestTime.value()
                if currentFastestTime == 0 {
                    defaults.set(timeRaced, forKey: PlayerStat.gkFastestTime.key)
                } else if timeRaced < Int(currentFastestTime) {
                    defaults.set(timeRaced, forKey: PlayerStat.gkFastestTime.key)
                }
                SKStoreReviewController.shouldPromptForRating = true
            } else {
                SKStoreReviewController.shouldPromptForRating = false
            }
        case .solo:
            PlayerStat.soloRaces.increment()
            PlayerStat.soloTotalTime.increment(by: Double(timeRaced))

            let currentFastestTime = PlayerStat.soloFastestTime.value()
            if currentFastestTime == 0 {
                defaults.set(timeRaced, forKey: PlayerStat.soloFastestTime.key)
            } else if timeRaced < Int(currentFastestTime) {
                defaults.set(timeRaced, forKey: PlayerStat.soloFastestTime.key)
            }

            SKStoreReviewController.shouldPromptForRating = true
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
                guard let stat = PlayerStat(rawValue: key) else { return }
                self.sync(stat, key: key)
            }
        }

        leaderboardSync()
        playerDatabaseSync()
    }

    private func sync(_ stat: PlayerStat, key: String) {
        if PlayerStat.numericHighStats.contains(stat) {
            let deviceValue = defaults.double(forKey: key)
            let cloudValue = keyValueStore.double(forKey: key)
            if deviceValue > cloudValue {
                keyValueStore.set(deviceValue, forKey: key)
            } else if cloudValue > deviceValue {
                defaults.set(cloudValue, forKey: key)
            }
        } else if PlayerStat.numericLowStats.contains(stat) {
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
        for stat in PlayerStat.numericHighStats {
            let deviceValue = defaults.double(forKey: stat.key)
            let cloudValue = keyValueStore.double(forKey: stat.key)
            if deviceValue > cloudValue {
                keyValueStore.set(deviceValue, forKey: stat.key)
            } else if cloudValue > deviceValue {
                defaults.set(cloudValue, forKey: stat.key)
            }
        }

        for stat in PlayerStat.numericLowStats {
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

    private func logStatToMetric(_ stat: PlayerStat) {
        let metrics = PlayerDatabaseMetrics.shared
        metrics.log(value: stat.value(), for: stat.key)
    }

    private func logAllStatsToMetric() {
        Set(PlayerStat.allCases)
            .subtracting([
                .bugHitCase1,
                .bugHitCase2,
                .bugHitCase3,
                .bugHitCase4,
                .bugHitCase5,
                .bugHitCase6,
                .bugHitCase7,
                .bugHitCase8
                ])
            .forEach { logStatToMetric($0) }
    }

    private func playerDatabaseSync() {
        logAllStatsToMetric()
        keyStatsUpdated?(combinedPoints,
                         combinedRaces,
                         PlayerStat.average.value())
    }

    private func leaderboardSync() {
        guard GKLocalPlayer.local.isAuthenticated else {
            return
        }

        let points = combinedPoints
        let races = combinedRaces
        let average = PlayerStat.average.value()

        let totalTime = combinedTotalTime
        let fastestTime = combinedFastestTime
        let pagesViewed = combinedPages

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
}
