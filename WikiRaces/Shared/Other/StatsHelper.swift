//
//  StatsHelper.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/31/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import GameKit
import CloudKit

class StatsHelper {

    // MARK: - Types

    enum Stat: String {
        case points
        case races
        case average

        // minutes
        case totalTime
        // seconds
        case fastestTime

        var key: String {
            return "WKRStat-" + self.rawValue
        }

        var leaderboard: String {
            switch self {
            case .points:       return "com.andrewfinke.wikiraces.points"
            case .races:        return "com.andrewfinke.wikiraces.races"
            case .average:      return "com.andrewfinke.wikiraces.ppr"
            case .totalTime:    return "com.andrewfinke.wikiraces.totaltime"
            case .fastestTime:  return "com.andrewfinke.wikiraces.fastesttime"
            }
        }
    }

    // MARK: - Properties

    static let shared = StatsHelper()

    var keyStatsUpdated: ((_ points: Double, _ races: Double, _ average: Double) -> Void)?
    private let migrationKey = "WKR3StatMigrationComplete"

    private let defaults = UserDefaults.standard
    private let keyValueStore = NSUbiquitousKeyValueStore.default

    init() {
        attemptMigration()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func start() {
        attemptMigration()
        cloudSync()
        leaderboardSync()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyValueStoreChanged(_:)),
                                               name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: keyValueStore)

        keyValueStore.synchronize()
    }

    func updateStatsClosure() {
        let races = statValue(for: .races)
        let points = statValue(for: .points)

        keyStatsUpdated?(points, races, statValue(for: .average))
        PlayerAnalytics.log(event: .updatedStats(points: Int(points), races: Int(races)))
    }

    // MARK: - Set/Get Stats

    func statValue(for stat: Stat) -> Double {
        if stat == .average {
            let value = statValue(for: .points) / statValue(for: .races)
            return value.isNaN ? 0.0 : value
        } else {
            return defaults.double(forKey: stat.key)
        }
    }

    func completedRace(points: Int, timeRaced: Int) {
        let newPoints = statValue(for: .points) + Double(points)
        let newRaces = statValue(for: .races) + 1
        let newTotalTime = statValue(for: .totalTime) + Double(timeRaced)

        defaults.set(newPoints, forKey: Stat.points.key)
        defaults.set(newRaces, forKey: Stat.races.key)
        defaults.set(newTotalTime, forKey: Stat.totalTime.key)

        // If found page, check for fastest completion time
        if points > 0 {
            let currentFastestTime = statValue(for: .fastestTime)
            if currentFastestTime == 0 {
                defaults.set(timeRaced, forKey: Stat.fastestTime.key)
            } else if timeRaced < Int(currentFastestTime) {
                print("Setting \(timeRaced)")
                defaults.set(timeRaced, forKey: Stat.fastestTime.key)
            }
        }

        cloudSync()
        leaderboardSync()
        updateStatsClosure()
    }

    private func attemptMigration() {
        guard !defaults.bool(forKey: migrationKey) else {
            return
        }

        let oldPoints = Double(UserDefaults.standard.integer(forKey: "Points"))
        let oldRaces = Double(UserDefaults.standard.integer(forKey: "Rounds"))

        defaults.set(oldPoints, forKey: Stat.points.key)
        defaults.set(oldRaces, forKey: Stat.races.key)
        defaults.set(true, forKey: migrationKey)

        cloudSync()
        leaderboardSync()
        updateStatsClosure()
    }

    // MARK: - Syncing

    @objc private func keyValueStoreChanged(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
            let reasonForChange = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber  else {
                return
        }

        let reason = reasonForChange.intValue
        if reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange {
            for key in changedKeys {
                let deviceValue = defaults.double(forKey: key)
                let cloudValue = keyValueStore.double(forKey: key)
                if deviceValue > cloudValue {
                    keyValueStore.set(deviceValue, forKey: key)
                } else {
                    defaults.set(deviceValue, forKey: key)
                }
            }
        }

        leaderboardSync()
        updateStatsClosure()
    }

    private func cloudSync() {
        let highValueStats = [Stat.points, Stat.races, Stat.totalTime]
        for stat in highValueStats {
            let deviceValue = defaults.double(forKey: stat.key)
            let cloudValue = keyValueStore.double(forKey: stat.key)
            if deviceValue > cloudValue {
                keyValueStore.set(deviceValue, forKey: stat.key)
            } else {
                defaults.set(cloudValue, forKey: stat.key)
            }
        }
        let lowValueStats = [Stat.fastestTime]
        for stat in lowValueStats {
            let deviceValue = defaults.double(forKey: stat.key)
            let cloudValue = keyValueStore.double(forKey: stat.key)
            if deviceValue < cloudValue {
                keyValueStore.set(deviceValue, forKey: stat.key)
            } else {
                defaults.set(cloudValue, forKey: stat.key)
            }
        }
    }

    private func leaderboardSync() {
        guard GKLocalPlayer.localPlayer().isAuthenticated else {
            return
        }

        let points = statValue(for: .points)
        let races = statValue(for: .races)
        let average = statValue(for: .average)

        let totalTime = statValue(for: .totalTime)
        let fastestTime = statValue(for: .fastestTime)

        let pointsScore = GKScore(leaderboardIdentifier: Stat.points.leaderboard)
        pointsScore.value = Int64(points)

        let racesScore = GKScore(leaderboardIdentifier: Stat.races.leaderboard)
        racesScore.value = Int64(races)

        let totalTimeScore = GKScore(leaderboardIdentifier: Stat.totalTime.leaderboard)
        totalTimeScore.value = Int64(totalTime / 60)

        var scores = [pointsScore, racesScore, totalTimeScore, totalTimeScore]
        if races >= 5 {
            let averageScore = GKScore(leaderboardIdentifier: Stat.average.leaderboard)
            averageScore.value = Int64(average * 1000)
            scores.append(averageScore)
        }
        if fastestTime > 0 {
            let fastestTimeScore = GKScore(leaderboardIdentifier: Stat.fastestTime.leaderboard)
            fastestTimeScore.value = Int64(fastestTime)
            scores.append(fastestTimeScore)
        }
        GKScore.report(scores, withCompletionHandler: nil)
    }

}
