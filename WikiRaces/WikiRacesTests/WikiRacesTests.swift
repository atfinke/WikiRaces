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

    func testMenuStats() {
        let menuView = MenuView()

        var stat = PlayerStat.mpcPressedJoin
        var value = stat.value()
        menuView.joinLocalRace()
        XCTAssertEqual(value + 1, stat.value())

        stat = PlayerStat.mpcPressedHost
        value = stat.value()
        menuView.createLocalRace()
        XCTAssertEqual(value + 1, stat.value())

        stat = PlayerStat.gkPressedJoin
        value = stat.value()
        menuView.joinGlobalRace()
        XCTAssertEqual(value + 1, stat.value())
    }

    func testViewedPage() {
        for raceIndex in 1...90 {
            guard let raceType = StatsHelper.RaceType(rawValue: (raceIndex % 3) + 1) else {
                XCTFail("race type nil")
                return
            }
            let pageStat: PlayerStat

            switch raceType {
            case .mpc:
                pageStat = .mpcPages
            case .gameKit:
                pageStat = .gkPages
            case .solo:
                pageStat = .soloPages
            }

            let value = Int(pageStat.value())
            StatsHelper.shared.viewedPage(raceType: raceType)
            XCTAssertEqual(value + 1, Int(pageStat.value()))
        }
    }

    func testConnected() {
        for raceIndex in 4...40 {
            guard let raceType = StatsHelper.RaceType(rawValue: (raceIndex % 2) + 1) else {
                XCTFail("race type nil")
                return
            }

            let playersKey: String
            var uniqueStat: PlayerStat
            var totalStat: PlayerStat
            switch raceType {
            case .mpc:
                playersKey = "PlayersArray"
                uniqueStat = .mpcUniquePlayers
                totalStat = .mpcTotalPlayers
            case .gameKit:
                playersKey = "GKPlayersArray"
                uniqueStat = .gkUniquePlayers
                totalStat = .gkTotalPlayers
            default: return
            }

            var existingPlayers = UserDefaults.standard.stringArray(forKey: playersKey) ?? []
            let maxPlayers = Int.random(in: 2..<(raceIndex * 2))
            let newPlayers = (1..<maxPlayers).map { $0.description }
            existingPlayers.append(contentsOf: newPlayers)

            StatsHelper.shared.connected(to: newPlayers, raceType: raceType)
            XCTAssertEqual(existingPlayers.count, Int(totalStat.value()))
            XCTAssertEqual(Set(existingPlayers).count, Int(uniqueStat.value()))
        }
    }

    func testFastestTimeStat() {
        for raceIndex in 1...90 {
            guard let raceType = StatsHelper.RaceType(rawValue: (raceIndex % 3) + 1) else {
                XCTFail("race type nil")
                return
            }

            let raceFastestTimeStat: PlayerStat

            switch raceType {
            case .mpc:
                raceFastestTimeStat = .mpcFastestTime
            case .gameKit:
                raceFastestTimeStat = .gkFastestTime
            case .solo:
                raceFastestTimeStat = .soloFastestTime
            }

            let fastest = Int(raceFastestTimeStat.value())
            let timeRaced = Int.random(in: (100 - raceIndex)...200)

            StatsHelper.shared.completedRace(type: raceType,
                                             points: 10,
                                             place: 1,
                                             timeRaced: timeRaced)

            var newTime = timeRaced
            if fastest != 0 {
                newTime = min(fastest, timeRaced)
            }
            XCTAssertEqual(newTime, Int(raceFastestTimeStat.value()))
        }
    }

    //swiftlint:disable:next cyclomatic_complexity function_body_length
    func testRaceCompletionStats() {
        var testedStats = Set<PlayerStat>()
        for raceIndex in 0..<600 {
            guard let raceType = StatsHelper.RaceType(rawValue: (raceIndex % 3) + 1) else {
                XCTFail("race type nil")
                return
            }

            let newPlace = Double(Int.random(in: 1..<5))
            let newPoints = Double(Int.random(in: 0...10))
            let newTimeRaced = Double(Int.random(in: 0...100))

            let raceCountStat: PlayerStat
            let racePointsStat: PlayerStat
            let racePlaceStat: PlayerStat
            let raceTimeStat: PlayerStat

            switch raceType {

            case .mpc:
                raceCountStat = .mpcRaces
                racePointsStat = .mpcPoints
                raceTimeStat = .mpcTotalTime
                if newPlace == 1 {
                    racePlaceStat = .mpcRaceFinishFirst
                } else if newPlace == 2 {
                    racePlaceStat = .mpcRaceFinishSecond
                } else if newPlace == 3 {
                    racePlaceStat = .mpcRaceFinishThird
                } else {
                    racePlaceStat = .mpcRaceDNF
                }
            case .gameKit:
                raceCountStat = .gkRaces
                racePointsStat = .gkPoints
                raceTimeStat = .gkTotalTime
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

                // N/A for solo
                racePointsStat = .soloHelp
                racePlaceStat = .soloHelp
            }

            let races = raceCountStat.value()
            let points = racePointsStat.value()
            let place = racePlaceStat.value()
            let timeRaced = raceTimeStat.value()

            StatsHelper.shared.completedRace(type: raceType,
                                             points: Int(newPoints),
                                             place: Int(newPlace),
                                             timeRaced: Int(newTimeRaced))

            if raceType != .solo {
                XCTAssertEqual(points + newPoints, racePointsStat.value())
                if newPlace <= 3 {
                    XCTAssertEqual(place + 1, racePlaceStat.value())
                }
            }
            XCTAssertEqual(races + 1, raceCountStat.value())
            XCTAssertEqual(timeRaced + newTimeRaced, raceTimeStat.value())
            testedStats = testedStats.union([raceCountStat, racePointsStat, racePlaceStat, raceTimeStat])
        }
        print("Tested: " + testedStats.map({ $0.rawValue }).sorted().description)
    }
}
