//
//  StatsHelper.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/31/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import CloudKit
import GameKit

//swiftlint:disable:next type_body_length
internal class StatsHelper {

    // MARK: - Types

    enum Stat: String {
        case points
        case races
        case average

        // minutes
        case totalTime
        // seconds
        case fastestTime

        case pages

        case totalPlayers
        case uniquePlayers

        case soloPages
        case soloTotalTime
        case soloRaces

        static var numericHighStats: [Stat] = [
            .points,
            .races,
            .average,
            .totalTime,
            .pages,
            .soloPages,
            .soloTotalTime,
            .soloRaces
        ]

        var key: String {
            return "WKRStat-" + self.rawValue
        }

        var leaderboard: String {
            switch self {
            case .points:        return "com.andrewfinke.wikiraces.points"
            case .races:         return "com.andrewfinke.wikiraces.races"
            case .average:       return "com.andrewfinke.wikiraces.ppr"
            case .totalTime:     return "com.andrewfinke.wikiraces.totaltime"
            case .fastestTime:   return "com.andrewfinke.wikiraces.fastesttime"
            case .pages:         return "com.andrewfinke.wikiraces.pages"
            case .totalPlayers, .uniquePlayers, .soloPages, .soloTotalTime, .soloRaces: fatalError()
            }
        }
    }

    // MARK: - Properties

    static let shared = StatsHelper()

    var keyStatsUpdated: ((_ points: Double, _ races: Double, _ average: Double) -> Void)?
    private let migrationKey = "WKR3StatMigrationComplete"

    private let defaults = UserDefaults.standard
    private let keyValueStore = NSUbiquitousKeyValueStore.default

    // MARK: - Initalization

    init() {
        attemptMigration()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Helpers

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

        let totalTime = statValue(for: .totalTime)
        let fastestTime = statValue(for: .fastestTime)

        let pages = statValue(for: .pages)

        let soloTotalTime = statValue(for: .soloTotalTime)
        let soloPages = statValue(for: .soloPages)
        let soloRaces = statValue(for: .soloRaces)

        keyStatsUpdated?(points, races, statValue(for: .average))
        PlayerMetrics.log(event: .updatedStats(points: Int(points),
                                                 races: Int(races),
                                                 totalTime: Int(totalTime),
                                                 fastestTime: Int(fastestTime),
                                                 pages: Int(pages),
                                                 soloTotalTime: Int(soloTotalTime),
                                                 soloPages: Int(soloPages),
                                                 soloRaces: Int(soloRaces)))
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

    func viewedPage(isSolo: Bool) {
        let stat: Stat = isSolo ? .soloPages : .pages
        let newPages = statValue(for: stat) + 1
        defaults.set(newPages, forKey: stat.key)
    }

    func connected(to players: [String]) {
        var existingPlayers = defaults.array(forKey: "PlayersArray") as? [String] ?? []
        existingPlayers += players
        defaults.set(existingPlayers, forKey: "PlayersArray")
        syncPlayerNamesStat()

        let uniquePlayers = Array(Set(existingPlayers)).count
        let totalPlayers = existingPlayers.count
        PlayerMetrics.log(event: .players(unique: uniquePlayers, total: totalPlayers))

        defaults.set(uniquePlayers, forKey: Stat.uniquePlayers.key)
        defaults.set(totalPlayers, forKey: Stat.totalPlayers.key)

        cloudSync()
    }

    func completedRace(points: Int, timeRaced: Int, isSolo: Bool) {
        if isSolo {
            let newSoloTotalTime = statValue(for: .soloTotalTime) + Double(timeRaced)
            let newSoloRaces = statValue(for: .soloRaces) + 1
            defaults.set(newSoloTotalTime, forKey: Stat.soloTotalTime.key)
            defaults.set(newSoloRaces, forKey: Stat.soloRaces.key)
            defaults.set(true, forKey: "ShouldPromptForRating")
        } else {
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
                    defaults.set(timeRaced, forKey: Stat.fastestTime.key)
                }
                defaults.set(true, forKey: "ShouldPromptForRating")
            } else {
                defaults.set(false, forKey: "ShouldPromptForRating")
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
                // Not currently syncing unique players array
                guard let stat = Stat(rawValue: key) else { return }

                if Stat.numericHighStats.contains(stat) {
                    let deviceValue = defaults.double(forKey: key)
                    let cloudValue = keyValueStore.double(forKey: key)
                    if deviceValue > cloudValue {
                        keyValueStore.set(deviceValue, forKey: key)
                    } else if cloudValue > deviceValue {
                        defaults.set(cloudValue, forKey: key)
                    }
                } else if stat == .fastestTime {
                    syncFastestTimeStat()
                } else if stat == .totalPlayers {
                    syncPlayerNamesStat()
                }
            }
        }

        leaderboardSync()
        updateStatsClosure()
    }

    private func cloudSync() {
        for stat in Stat.numericHighStats {
            let deviceValue = defaults.double(forKey: stat.key)
            let cloudValue = keyValueStore.double(forKey: stat.key)
            if deviceValue > cloudValue {
                keyValueStore.set(deviceValue, forKey: stat.key)
            } else if cloudValue > deviceValue {
                defaults.set(cloudValue, forKey: stat.key)
            }
        }

        syncFastestTimeStat()
        syncPlayerNamesStat()
    }

    private func syncFastestTimeStat() {
        let stat = Stat.fastestTime
        let deviceValue = defaults.double(forKey: stat.key)
        let cloudValue = keyValueStore.double(forKey: stat.key)
        if cloudValue < deviceValue && cloudValue != 0.0 {
            defaults.set(cloudValue, forKey: stat.key)
        } else if deviceValue != 0.0 {
            keyValueStore.set(deviceValue, forKey: stat.key)
        }
    }

    private func syncPlayerNamesStat() {
        let stat = "PlayersArray"
        let deviceValue = defaults.array(forKey: stat) ?? []
        let cloudValue = keyValueStore.array(forKey: stat) ?? []
        if deviceValue.count < cloudValue.count {
            defaults.set(cloudValue, forKey: stat)
        } else if cloudValue.count < deviceValue.count {
            keyValueStore.set(deviceValue, forKey: stat)
        }
    }

    private func leaderboardSync() {
        guard GKLocalPlayer.local.isAuthenticated else {
            return
        }

        let points = statValue(for: .points)
        let races = statValue(for: .races)
        let average = statValue(for: .average)

        let totalTime = statValue(for: .totalTime)
        let fastestTime = statValue(for: .fastestTime)

        let pagesViewed = statValue(for: .pages)

        let pointsScore = GKScore(leaderboardIdentifier: Stat.points.leaderboard)
        pointsScore.value = Int64(points)

        let racesScore = GKScore(leaderboardIdentifier: Stat.races.leaderboard)
        racesScore.value = Int64(races)

        let totalTimeScore = GKScore(leaderboardIdentifier: Stat.totalTime.leaderboard)
        totalTimeScore.value = Int64(totalTime / 60)

        let pagesViewedScore = GKScore(leaderboardIdentifier: Stat.pages.leaderboard)
        pagesViewedScore.value = Int64(pagesViewed)

        // Waiting to see what these stats look like
        // let playersRacedScore = GKScore(leaderboardIdentifier: Stat.uniquePlayers.leaderboard)
        // playersRacedScore.value = Int64(playersRaced)

        var scores = [pointsScore, racesScore, totalTimeScore, totalTimeScore, pagesViewedScore]
        if races >= 5 {
            let averageScore = GKScore(leaderboardIdentifier: Stat.average.leaderboard)
            averageScore.value = Int64(average * 1_000)
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
