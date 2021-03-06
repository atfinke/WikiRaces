//
//  WikiRacesTests.swift
//  WikiRacesTests
//
//  Created by Andrew Finke on 3/6/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import XCTest
@testable import WikiRaces

class WikiRacesTests: XCTestCase {

    override func setUp() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            for key in NSUbiquitousKeyValueStore.default.dictionaryRepresentation.keys {
                NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
            }
        }
    }

    override func tearDown() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            for key in NSUbiquitousKeyValueStore.default.dictionaryRepresentation.keys {
                NSUbiquitousKeyValueStore.default.removeObject(forKey: key)
            }
        }
    }

    func testRaceCodePlayerGroupGeneration() {
        for code in RaceCodeGenerator.codes {
            _ = RaceCodeGenerator.playerGroup(for: code)
        }
    }

    func testViewedPage() {
        for raceIndex in 1...90 {
            guard let raceType = PlayerStatsManager.RaceType(rawValue: (raceIndex % 3) + 1) else {
                XCTFail("race type nil")
                return
            }
            let pageStat: PlayerUserDefaultsStat

            switch raceType {
            case .private:
                pageStat = .mpcPages
            case .public:
                pageStat = .gkPages
            case .solo:
                pageStat = .soloPages
            }

            let value = Int(pageStat.value())
            PlayerStatsManager.shared.viewedPage(raceType: raceType)
            XCTAssertEqual(value + 1, Int(pageStat.value()))
        }
    }

    func testConnected() {
        for raceIndex in 4...40 {
            guard let raceType = PlayerStatsManager.RaceType(rawValue: (raceIndex % 2) + 1) else {
                XCTFail("race type nil")
                return
            }

            let playersKey: String
            var uniqueStat: PlayerUserDefaultsStat
            var totalStat: PlayerUserDefaultsStat
            switch raceType {
            case .private:
                playersKey = "PlayersArray"
                uniqueStat = .mpcUniquePlayers
                totalStat = .mpcTotalPlayers
            case .public:
                playersKey = "GKPlayersArray"
                uniqueStat = .gkUniquePlayers
                totalStat = .gkTotalPlayers
            default: return
            }

            var existingPlayers = UserDefaults.standard.stringArray(forKey: playersKey) ?? []
            let maxPlayers = Int.random(in: 2..<(raceIndex * 2))
            let newPlayers = (1..<maxPlayers).map { $0.description }
            existingPlayers.append(contentsOf: newPlayers)

            PlayerStatsManager.shared.connected(to: newPlayers, raceType: raceType)
            XCTAssertEqual(existingPlayers.count, Int(totalStat.value()))
            XCTAssertEqual(Set(existingPlayers).count, Int(uniqueStat.value()))
        }
    }

    func testFastestTimeStat() {
        for raceIndex in 1...90 {
            guard let raceType = PlayerStatsManager.RaceType(rawValue: (raceIndex % 3) + 1) else {
                XCTFail("race type nil")
                return
            }

            let raceFastestTimeStat: PlayerUserDefaultsStat

            switch raceType {
            case .private:
                raceFastestTimeStat = .mpcFastestTime
            case .public:
                raceFastestTimeStat = .gkFastestTime
            case .solo:
                raceFastestTimeStat = .soloFastestTime
            }

            let fastest = Int(raceFastestTimeStat.value())
            let timeRaced = Int.random(in: (100 - raceIndex)...200)

            PlayerStatsManager.shared.completedRace(type: raceType,
                                             points: 10,
                                             place: 1,
                                             timeRaced: timeRaced,
                                             pixelsScrolled: 0,
                                             pages: [],
                                             isEligibleForPoints: true,
                                             isEligibleForSpeed: true)

            var newTime = timeRaced
            if fastest != 0 {
                newTime = min(fastest, timeRaced)
            }
            XCTAssertEqual(newTime, Int(raceFastestTimeStat.value()))
        }
    }

    func testRaceCompletionStats() {
        var testedStats = Set<PlayerUserDefaultsStat>()
        for raceIndex in 0..<600 {
            guard let raceType = PlayerStatsManager.RaceType(rawValue: (raceIndex % 3) + 1) else {
                XCTFail("race type nil")
                return
            }

            let newPlace = Double(Int.random(in: 1..<5))
            let newPoints = Double(Int.random(in: 0...10))
            let newTimeRaced = Double(Int.random(in: 0...100))
            let newPixelsScrolled = Double(Int.random(in: 0...100000))

            let raceCountStat: PlayerUserDefaultsStat
            let racePointsStat: PlayerUserDefaultsStat
            let racePlaceStat: PlayerUserDefaultsStat
            let raceTimeStat: PlayerUserDefaultsStat
            let racePixelsScrolledStat: PlayerUserDefaultsStat

            switch raceType {

            case .private:
                raceCountStat = .mpcRaces
                racePointsStat = .mpcPoints
                raceTimeStat = .mpcTotalTime
                racePixelsScrolledStat = .mpcPixelsScrolled
                if newPlace == 1 {
                    racePlaceStat = .mpcRaceFinishFirst
                } else if newPlace == 2 {
                    racePlaceStat = .mpcRaceFinishSecond
                } else if newPlace == 3 {
                    racePlaceStat = .mpcRaceFinishThird
                } else {
                    racePlaceStat = .mpcRaceDNF
                }
            case .public:
                raceCountStat = .gkRaces
                racePointsStat = .gkPoints
                raceTimeStat = .gkTotalTime
                racePixelsScrolledStat = .gkPixelsScrolled
                if newPlace == 1 {
                    racePlaceStat = .gkRaceFinishFirst
                } else if newPlace == 2 {
                    racePlaceStat = .gkRaceFinishSecond
                } else if newPlace == 3 {
                    racePlaceStat = .gkRaceFinishThird
                } else {
                    racePlaceStat = .gkRaceDNF
                }
            case .solo:
                raceCountStat = .soloRaces
                raceTimeStat = .soloTotalTime
                racePixelsScrolledStat = .soloPixelsScrolled

                // N/A for solo
                racePointsStat = .soloHelp
                racePlaceStat = .soloHelp
            }

            let races = raceCountStat.value()
            let points = racePointsStat.value()
            let place = racePlaceStat.value()
            let timeRaced = raceTimeStat.value()
            let racePixelsScrolled = racePixelsScrolledStat.value()

            PlayerStatsManager.shared.completedRace(type: raceType,
                                             points: Int(newPoints),
                                             place: Int(newPlace),
                                             timeRaced: Int(newTimeRaced),
                                             pixelsScrolled: Int(newPixelsScrolled),
                                             pages: [],
                                             isEligibleForPoints: true,
                                             isEligibleForSpeed: true)

            if raceType != .solo {
                XCTAssertEqual(points + newPoints, racePointsStat.value())
                if newPlace <= 3 {
                    XCTAssertEqual(place + 1, racePlaceStat.value())
                }
            }
            XCTAssertEqual(races + 1, raceCountStat.value())
            XCTAssertEqual(racePixelsScrolled + newPixelsScrolled, racePixelsScrolledStat.value())
            XCTAssertEqual(timeRaced + newTimeRaced, raceTimeStat.value())
            testedStats = testedStats.union([
                raceCountStat,
                racePointsStat,
                racePlaceStat,
                raceTimeStat,
                racePixelsScrolledStat
                ])
        }
        print("Tested: " + testedStats.map({ $0.rawValue }).sorted().description)
    }
}
