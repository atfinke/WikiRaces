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
internal class PlayerStatsManager {

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

    static let shared = PlayerStatsManager()

    var menuStatsUpdated: ((_ points: Double, _ races: Double, _ average: Double) -> Void)?

    private let defaults = UserDefaults.standard
    private let keyValueStore = NSUbiquitousKeyValueStore.default

    // MARK: - Computed Properties

    var multiplayerPoints: Double {
        return PlayerDatabaseStat.mpcPoints.value() + PlayerDatabaseStat.gkPoints.value()
    }

    var multiplayerRaces: Double {
        return PlayerDatabaseStat.mpcRaces.value() + PlayerDatabaseStat.gkRaces.value()
    }

    var multiplayerPages: Double {
        return PlayerDatabaseStat.mpcPages.value() + PlayerDatabaseStat.gkPages.value()
    }

    var multiplayerPixelsScrolled: Double {
        return PlayerDatabaseStat.mpcPixelsScrolled.value() + PlayerDatabaseStat.gkPixelsScrolled.value()
    }

    var multiplayerTotalTime: Double {
        return PlayerDatabaseStat.mpcTotalTime.value() + PlayerDatabaseStat.gkTotalTime.value()
    }

    var multiplayerFastestTime: Double {
        let mpcTime = PlayerDatabaseStat.mpcFastestTime.value()
        if mpcTime == 0 {
            return PlayerDatabaseStat.gkFastestTime.value()
        } else {
            let gkTime = PlayerDatabaseStat.gkFastestTime.value()
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
        var stat: PlayerDatabaseStat
        switch raceType {
        case .mpc:
            stat = PlayerDatabaseStat.mpcPages
        case .gameKit:
            stat = PlayerDatabaseStat.gkPages
        case .solo:
            stat = PlayerDatabaseStat.soloPages
        }
        stat.increment()
    }

    func connected(to players: [String], raceType: RaceType) {
        var playersKey = ""
        var uniqueStat = PlayerDatabaseStat.mpcUniquePlayers
        var totalStat = PlayerDatabaseStat.mpcTotalPlayers
        let matchStat: PlayerDatabaseStat
        switch raceType {
        case .mpc:
            playersKey = "PlayersArray"
            uniqueStat = PlayerDatabaseStat.mpcUniquePlayers
            totalStat = PlayerDatabaseStat.mpcTotalPlayers
            matchStat = .mpcMatch
        case .gameKit:
            playersKey = "GKPlayersArray"
            uniqueStat = PlayerDatabaseStat.gkUniquePlayers
            totalStat = PlayerDatabaseStat.gkTotalPlayers
            matchStat = .gkMatch
        case .solo:
            matchStat = .soloMatch
        }

        var existingPlayers = defaults.stringArray(forKey: playersKey) ?? []
        existingPlayers += players
        defaults.set(existingPlayers, forKey: playersKey)
        syncPlayerNamesStat(raceType: raceType)

        let uniquePlayers = Array(Set(existingPlayers)).count
        let totalPlayers = existingPlayers.count

        defaults.set(uniquePlayers, forKey: uniqueStat.key)
        defaults.set(totalPlayers, forKey: totalStat.key)

        matchStat.increment()

        logStatToMetric(matchStat)
        logStatToMetric(.mpcUniquePlayers)
        logStatToMetric(.mpcTotalPlayers)
        logStatToMetric(.gkUniquePlayers)
        logStatToMetric(.gkTotalPlayers)

        ubiquitousStoreSync()
    }

    //swiftlint:disable:next function_body_length
    func completedRace(type: RaceType, points: Int, place: Int?, timeRaced: Int, pixelsScrolled: Int) {
        let pointsStat: PlayerDatabaseStat?
        let racesStat: PlayerDatabaseStat
        let totalTimeStat: PlayerDatabaseStat
        let fastestTimeStat: PlayerDatabaseStat
        let pixelsStat: PlayerDatabaseStat

        let finishFirstStat: PlayerDatabaseStat
        let finishSecondStat: PlayerDatabaseStat?
        let finishThirdStat: PlayerDatabaseStat?
        let finishDNFStat: PlayerDatabaseStat

        switch type {
        case .mpc:
            pointsStat = .mpcPoints
            racesStat = .mpcRaces
            totalTimeStat = .mpcTotalTime
            fastestTimeStat = .mpcFastestTime
            pixelsStat = .mpcPixelsScrolled

            finishFirstStat = .mpcRaceFinishFirst
            finishSecondStat = .mpcRaceFinishSecond
            finishThirdStat = .mpcRaceFinishThird
            finishDNFStat = .mpcRaceDNF
        case .gameKit:
            pointsStat = .gkPoints
            racesStat = .gkRaces
            totalTimeStat = .gkTotalTime
            fastestTimeStat = .gkFastestTime
            pixelsStat = .gkPixelsScrolled

            finishFirstStat = .gkRaceFinishFirst
            finishSecondStat = .gkRaceFinishSecond
            finishThirdStat = .gkRaceFinishThird
            finishDNFStat = .gkRaceDNF
        case .solo:
            pointsStat = nil
            racesStat = .soloRaces
            totalTimeStat = .soloTotalTime
            fastestTimeStat = .soloFastestTime
            pixelsStat = .soloPixelsScrolled

            finishFirstStat = .soloRaceFinishFirst
            finishSecondStat = nil
            finishThirdStat = nil
            finishDNFStat = .soloRaceDNF
        }

        pointsStat?.increment(by: Double(points))
        racesStat.increment()
        totalTimeStat.increment(by: Double(timeRaced))
        pixelsStat.increment(by: Double(pixelsScrolled))

        if let place = place {
            if place == 1 {
                finishFirstStat.increment()
            } else if place == 2 {
                finishSecondStat?.increment()
            } else if place == 3 {
                finishThirdStat?.increment()
            }

            let currentFastestTime = fastestTimeStat.value()
            if currentFastestTime == 0 {
                defaults.set(timeRaced, forKey: fastestTimeStat.key)
            } else if timeRaced < Int(currentFastestTime) {
                defaults.set(timeRaced, forKey: fastestTimeStat.key)
            }
            SKStoreReviewController.shouldPromptForRating = true
        } else {
            finishDNFStat.increment()
            SKStoreReviewController.shouldPromptForRating = false
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
                guard let stat = PlayerDatabaseStat(rawValue: key) else { return }
                self.sync(stat, key: key)
            }
        }

        leaderboardSync()
        playerDatabaseSync()
    }

    private func sync(_ stat: PlayerDatabaseStat, key: String) {
        if PlayerDatabaseStat.numericHighStats.contains(stat) {
            let deviceValue = defaults.double(forKey: key)
            let cloudValue = keyValueStore.double(forKey: key)
            if deviceValue > cloudValue {
                keyValueStore.set(deviceValue, forKey: key)
            } else if cloudValue > deviceValue {
                defaults.set(cloudValue, forKey: key)
            }
        } else if PlayerDatabaseStat.numericLowStats.contains(stat) {
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
        for stat in PlayerDatabaseStat.numericHighStats {
            let deviceValue = defaults.double(forKey: stat.key)
            let cloudValue = keyValueStore.double(forKey: stat.key)
            if deviceValue > cloudValue {
                keyValueStore.set(deviceValue, forKey: stat.key)
            } else if cloudValue > deviceValue {
                defaults.set(cloudValue, forKey: stat.key)
            }
        }
        for stat in PlayerDatabaseStat.numericLowStats {
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

    private func logStatToMetric(_ stat: PlayerDatabaseStat) {
        let metrics = PlayerDatabaseMetrics.shared
        metrics.log(value: stat.value(), for: stat.rawValue)
    }

    private func logAllStatsToMetric() {
        Set(PlayerDatabaseStat.allCases).forEach { logStatToMetric($0) }
    }

    private func playerDatabaseSync() {
        logAllStatsToMetric()
        menuStatsUpdated?(multiplayerPoints,
                         multiplayerRaces,
                         PlayerDatabaseStat.average.value())
    }

    private func leaderboardSync() {
        guard GKLocalPlayer.local.isAuthenticated else {
            return
        }

        let points = multiplayerPoints
        let races = multiplayerRaces
        let average = PlayerDatabaseStat.average.value()

        let totalTime = multiplayerTotalTime
        let fastestTime = multiplayerFastestTime
        let pagesViewed = multiplayerPages
        let pixelsScrolled = multiplayerPixelsScrolled

        let pointsScore = GKScore(leaderboardIdentifier: "com.andrewfinke.wikiraces.points")
        pointsScore.value = Int64(points)

        let racesScore = GKScore(leaderboardIdentifier: "com.andrewfinke.wikiraces.races")
        racesScore.value = Int64(races)

        let totalTimeScore = GKScore(leaderboardIdentifier: "com.andrewfinke.wikiraces.totaltime")
        totalTimeScore.value = Int64(totalTime / 60)

        let pagesViewedScore = GKScore(leaderboardIdentifier: "com.andrewfinke.wikiraces.pages")
        pagesViewedScore.value = Int64(pagesViewed)

        let pixelsScrolledScore = GKScore(leaderboardIdentifier: "com.andrewfinke.wikiraces.pixelsscrolled")
        pixelsScrolledScore.value = Int64(pixelsScrolled)

        var scores = [
            pointsScore,
            racesScore,
            totalTimeScore,
            totalTimeScore,
            pagesViewedScore,
            pixelsScrolledScore
        ]

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
