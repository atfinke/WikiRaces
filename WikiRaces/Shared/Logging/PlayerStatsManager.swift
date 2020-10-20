//
//  PlayerStatsManager.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/31/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import CloudKit
import GameKit
import StoreKit

import WKRKit

final internal class PlayerStatsManager {

    // MARK: - Types

    enum RaceType: Int {
        case `private` = 1, `public` = 2, solo = 3

        init?(_ config: WKRPeerNetworkConfig) {
            switch config {
            case .solo:
                self = .solo
            case .gameKitPublic:
                self = .public
            case .gameKitPrivate:
                self = .private
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

    // MARK: - Initalization -

    private init() {}

    // MARK: - Computed Properties

    var multiplayerPoints: Double {
        return PlayerUserDefaultsStat.mpcPoints.value() + PlayerUserDefaultsStat.gkPoints.value()
    }

    var multiplayerRaces: Double {
        return PlayerUserDefaultsStat.mpcRaces.value() + PlayerUserDefaultsStat.gkRaces.value()
    }

    var multiplayerPages: Double {
        return PlayerUserDefaultsStat.mpcPages.value() + PlayerUserDefaultsStat.gkPages.value()
    }

    var multiplayerPixelsScrolled: Double {
        return PlayerUserDefaultsStat.mpcPixelsScrolled.value() + PlayerUserDefaultsStat.gkPixelsScrolled.value()
    }

    var multiplayerTotalTime: Double {
        return PlayerUserDefaultsStat.mpcTotalTime.value() + PlayerUserDefaultsStat.gkTotalTime.value()
    }

    var multiplayerFastestTime: Double {
        let mpcTime = PlayerUserDefaultsStat.mpcFastestTime.value()
        if mpcTime == 0 {
            return PlayerUserDefaultsStat.gkFastestTime.value()
        } else {
            let gkTime = PlayerUserDefaultsStat.gkFastestTime.value()
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
        var stat: PlayerUserDefaultsStat
        switch raceType {
        case .private:
            stat = PlayerUserDefaultsStat.mpcPages
        case .public:
            stat = PlayerUserDefaultsStat.gkPages
        case .solo:
            stat = PlayerUserDefaultsStat.soloPages
        }
        stat.increment()
    }

    func connected(to players: [String], raceType: RaceType) {
        var playersKey = ""
        var uniqueStat = PlayerUserDefaultsStat.mpcUniquePlayers
        var totalStat = PlayerUserDefaultsStat.mpcTotalPlayers
        let matchStat: PlayerUserDefaultsStat
        switch raceType {
        case .private:
            playersKey = "PlayersArray"
            uniqueStat = PlayerUserDefaultsStat.mpcUniquePlayers
            totalStat = PlayerUserDefaultsStat.mpcTotalPlayers
            matchStat = .mpcMatch
        case .public:
            playersKey = "GKPlayersArray"
            uniqueStat = PlayerUserDefaultsStat.gkUniquePlayers
            totalStat = PlayerUserDefaultsStat.gkTotalPlayers
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

    func completedRace(
        type: RaceType,
        points: Int,
        place: Int?,
        timeRaced: Int,
        pixelsScrolled: Int,
        pages: [WKRPage],
        isEligibleForPoints: Bool,
        isEligibleForSpeed: Bool) {

        let pointsStat: PlayerUserDefaultsStat?
        let racesStat: PlayerUserDefaultsStat
        let totalTimeStat: PlayerUserDefaultsStat
        let fastestTimeStat: PlayerUserDefaultsStat
        let pixelsStat: PlayerUserDefaultsStat

        let finishFirstStat: PlayerUserDefaultsStat
        let finishSecondStat: PlayerUserDefaultsStat?
        let finishThirdStat: PlayerUserDefaultsStat?
        let finishDNFStat: PlayerUserDefaultsStat

        switch type {
        case .private:
            pointsStat = .mpcPoints
            racesStat = .mpcRaces
            totalTimeStat = .mpcTotalTime
            fastestTimeStat = .mpcFastestTime
            pixelsStat = .mpcPixelsScrolled

            finishFirstStat = .mpcRaceFinishFirst
            finishSecondStat = .mpcRaceFinishSecond
            finishThirdStat = .mpcRaceFinishThird
            finishDNFStat = .mpcRaceDNF
        case .public:
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

        if isEligibleForPoints {
            pointsStat?.increment(by: Double(points))
            racesStat.increment()
        }

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

            if isEligibleForSpeed {
                let currentFastestTime = fastestTimeStat.value()
                if currentFastestTime == 0 || timeRaced < Int(currentFastestTime) {
                    fastestTimeStat.set(value: Double(timeRaced))
                }
            }
            Defaults.shouldPromptForRating = true
        } else {
            finishDNFStat.increment()
            Defaults.shouldPromptForRating = false
        }

        ubiquitousStoreSync()
        leaderboardSync()
        playerDatabaseSync()

        DispatchQueue.global(qos: .utility).async {
            let manager = FileManager.default
            guard let docs = manager.urls(for: .documentDirectory, in: .userDomainMask).last else { fatalError() }
            let pagesViewedDir = docs.appendingPathComponent("PagesViewed")
            try? manager.createDirectory(at: pagesViewedDir, withIntermediateDirectories: false, attributes: nil)

            let totalsFileURL = pagesViewedDir.appendingPathComponent("Totals.txt")
            var seenPages: [WKRPage: Int]
            if let data = try? Data(contentsOf: totalsFileURL),
                let diskPages = try? JSONDecoder().decode([WKRPage: Int].self, from: data) {
                seenPages = diskPages
            } else {
                seenPages = [:]
            }

            for page in pages {
                if let existing = seenPages[page] {
                    seenPages[page] = existing + 1
                } else {
                    seenPages[page] = 1
                }
            }

            let encoder = JSONEncoder()
            if let data = try? encoder.encode(seenPages) {
                try? data.write(to: totalsFileURL)
            }

            let date = Date().timeIntervalSince1970.description.split(separator: ".")[0]
            let url = pagesViewedDir.appendingPathComponent(date + ".txt")
            if let data = try? encoder.encode(pages) {
                try? data.write(to: url)
            }
        }
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
                guard let stat = PlayerUserDefaultsStat(rawValue: key) else { return }
                self.sync(stat, key: key)
            }
        }

        leaderboardSync()
        playerDatabaseSync()
    }

    private func sync(_ stat: PlayerUserDefaultsStat, key: String) {
        if PlayerUserDefaultsStat.numericHighStats.contains(stat) {
            let deviceValue = defaults.double(forKey: key)
            let cloudValue = keyValueStore.double(forKey: key)
            if deviceValue > cloudValue {
                keyValueStore.set(deviceValue, forKey: key)
            } else if cloudValue > deviceValue {
                defaults.set(cloudValue, forKey: key)
            }
        } else if PlayerUserDefaultsStat.numericLowStats.contains(stat) {
            let deviceValue = defaults.double(forKey: stat.key)
            let cloudValue = keyValueStore.double(forKey: stat.key)
            if cloudValue < deviceValue && cloudValue != 0.0 {
                defaults.set(cloudValue, forKey: stat.key)
            } else if deviceValue != 0.0 {
                keyValueStore.set(deviceValue, forKey: stat.key)
            }
        } else if stat == .mpcTotalPlayers {
            syncPlayerNamesStat(raceType: .private)
        } else if stat == .gkTotalPlayers {
            syncPlayerNamesStat(raceType: .public)
        }
    }

    private func ubiquitousStoreSync() {
        for stat in PlayerUserDefaultsStat.numericHighStats {
            let deviceValue = defaults.double(forKey: stat.key)
            let cloudValue = keyValueStore.double(forKey: stat.key)
            if deviceValue > cloudValue {
                keyValueStore.set(deviceValue, forKey: stat.key)
            } else if cloudValue > deviceValue {
                defaults.set(cloudValue, forKey: stat.key)
            }
        }
        for stat in PlayerUserDefaultsStat.numericLowStats {
            let deviceValue = defaults.double(forKey: stat.key)
            let cloudValue = keyValueStore.double(forKey: stat.key)
            if cloudValue < deviceValue && cloudValue != 0.0 {
                defaults.set(cloudValue, forKey: stat.key)
            } else if deviceValue != 0.0 {
                keyValueStore.set(deviceValue, forKey: stat.key)
            }
        }

        syncPlayerNamesStat(raceType: .private)
        syncPlayerNamesStat(raceType: .public)
    }

    private func syncPlayerNamesStat(raceType: RaceType) {
        var stat = ""
        if raceType == .private {
            stat = "PlayersArray"
        } else if raceType == .public {
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

    private func logStatToMetric(_ stat: PlayerUserDefaultsStat) {
        let metrics = PlayerCloudKitStatsManager.shared
        metrics.log(value: stat.value(), for: stat.rawValue)
    }

    private func logAllStatsToMetric() {
        Set(PlayerUserDefaultsStat.allCases).forEach { logStatToMetric($0) }
    }

    private func playerDatabaseSync() {
        logAllStatsToMetric()
        menuStatsUpdated?(multiplayerPoints,
                          multiplayerRaces,
                          PlayerUserDefaultsStat.multiplayerAverage.value())
    }

    private func leaderboardSync() {
        guard GKLocalPlayer.local.isAuthenticated else {
            return
        }

        let points = multiplayerPoints
        let races = multiplayerRaces
        let average = PlayerUserDefaultsStat.multiplayerAverage.value()

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
