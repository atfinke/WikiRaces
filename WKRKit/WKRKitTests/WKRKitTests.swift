//
//  WKRKitTests.swift
//  WKRKitTests
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import XCTest
@testable import WKRKit

//swiftlint:disable:next
class WKRKitTests: WKRKitTestCase {

    // MARK: - WKRGameState

    func testState() {
        var state = WKRGameState.voting
        testEnumEncoding(for: state)

        state = WKRGameState.race
        testEnumEncoding(for: state)
    }

    // MARK: - WKRHistory

    func testHistory() {
        let startingPage = WKRPage.mockApple(withSuffix: "1")
        let endingPage = WKRPage.mockApple(withSuffix: "2")

        var historyOne = WKRHistory(firstPage: startingPage)
        historyOne.append(startingPage, linkHere: false)
        XCTAssertNil(historyOne.duration)

        historyOne.finishedViewingLastPage()
        XCTAssertNotNil(historyOne.entries.first?.duration)
        XCTAssertLessThan(historyOne.entries[0].duration ?? 1, 1)
        XCTAssertLessThan(historyOne.duration!, 1)

        historyOne.append(endingPage, linkHere: false)

        var historyTwo = WKRHistory(firstPage: endingPage)
        historyTwo.append(endingPage, linkHere: false)
        historyTwo.append(startingPage, linkHere: false)

        testEncoding(for: historyOne)
        testEncoding(for: historyTwo)

        XCTAssertNotEqual(historyOne, historyTwo)
    }

    func testRaceConfig() {
        let starting = WKRPage.mockApple(withSuffix: "1")
        let ending = WKRPage.mockApple(withSuffix: "2")
        let raceConfig = WKRRaceConfig(starting: starting, ending: ending)
        XCTAssertEqual(raceConfig.startingPage, starting)
        XCTAssertEqual(raceConfig.endingPage, ending)
    }

    // MARK: - WKRRace

    func testRace() {
        let starting = WKRPage.mockApple(withSuffix: "1")
        let ending = WKRPage.mockApple(withSuffix: "2")
        let raceConfig = WKRRaceConfig(starting: starting, ending: ending)

        var race = WKRRace(config: raceConfig, isSolo: false)

        let playerOne = WKRPlayer.mock(named: "Andrew")
        playerOne.startedNewRace(on: starting)
        playerOne.finishedViewingLastPage(pixelsScrolled: 0)
        race.playerUpdated(playerOne)
        XCTAssertEqual(race.players.count, 1)

        let playerTwo = WKRPlayer.mock(named: "Midnight")
        playerTwo.startedNewRace(on: starting)
        sleep(1)
        playerTwo.finishedViewingLastPage(pixelsScrolled: 0)
        race.playerUpdated(playerTwo)
        XCTAssertEqual(race.players.count, 2)

        let playerThree = WKRPlayer.mock(named: "Carol")
        playerThree.startedNewRace(on: starting)
        race.playerUpdated(playerThree)
        XCTAssertEqual(race.players.count, 3)

        XCTAssertFalse(race.shouldEnd())

        playerOne.state = .foundPage
        playerTwo.state = .foundPage
        race.playerUpdated(playerOne)
        race.playerUpdated(playerTwo)

        XCTAssertEqual(race.players.count, 3)
        XCTAssertTrue(race.shouldEnd())

        let points = race.calculatePoints()
        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[playerOne.profile], 2)
        XCTAssertEqual(points[playerTwo.profile], 1)
        XCTAssertNil(points[playerThree.profile])

        // same page
        XCTAssertTrue(race.attributes(for: ending).foundPage)

        // dif title, same url
        XCTAssertTrue(race.attributes(for: WKRPage(title: "DifTitle", url: ending.url)).foundPage)

        // same title, dif url
        XCTAssertTrue(race.attributes(for: WKRPage(title: "Apple", url: starting.url)).foundPage)

//        https://en.m.wikipedia.org/wiki/Forward_pass#American_and_Canadian_football

        if let url = URL(string: ending.url.absoluteString + "#section") {
            // same title, url w/ section
            XCTAssertTrue(race.attributes(for: WKRPage(title: "Apple", url: url)).foundPage)

            // dif title, url w/ section
            XCTAssertTrue(race.attributes(for: WKRPage(title: "DifTitle", url: url)).foundPage)
        } else {
            XCTFail("url nil")
        }

        // dif title, dif url
        XCTAssertFalse(race.attributes(for: WKRPage(title: "Dif", url: URL(string: "http://a.com")!)).foundPage)
    }

    // MARK: - WKRInt

    func testInt() {
        let intTypes: [WKRInt.WKRIntType] = [
            .votingTime,
            .votingPreRaceTime,
            .resultsTime,
            .bonusPoints,
            .showReady
        ]

        var stateValue = 0
        for intType in intTypes {
            XCTAssertEqual(stateValue, intType.rawValue)
            stateValue += 1

            let object = WKRInt(type: intType, value: 100)
            XCTAssertEqual(object.type, intType)
            XCTAssertEqual(object.value, 100)
        }
    }

    // MARK: - WKRPlayerState

    func testPlayerState() {
        let states: [WKRPlayerState] = [
            .racing,
            .foundPage,
            .forcedEnd,
            .forfeited,
            .readyForNextRound,
            .voting,
            .quit,
            .connecting
        ]

        for state in states {
            _ = state.text
        }
    }

    // MARK: - WKRPlayerProfile

    func testPlayerProfile() {
        let profileA = WKRPlayerProfile.mock(named: "A")
        let profileB = WKRPlayerProfile.mock(named: "B")
        let profileC = WKRPlayerProfile.mock(named: "B")

        testEncoding(for: profileA)
        testEncoding(for: profileB)

        XCTAssertNotEqual(profileA, profileB)
        XCTAssertNotEqual(profileB, profileC)
        XCTAssertEqual(profileB, profileB)
    }

    // MARK: - WKRPlayer

    func testPlayer() {
        let name = "Andrew"
        let uuid = "1010101"
        let profile = WKRPlayerProfile(name: name, playerID: uuid)
        let player = WKRPlayer(profile: profile, isHost: false)

        XCTAssert(player.profile.name == name)
        XCTAssert(player.profile.playerID == uuid)

        testEncoding(for: player)
    }

    func testPlayerHistory() {
        let name = "Andrew"
        let uuid = "1010101"
        let profile = WKRPlayerProfile(name: name, playerID: uuid)
        let player = WKRPlayer(profile: profile, isHost: false)

        let page =  WKRPage.mockApple()
        player.startedNewRace(on: page)
        player.finishedViewingLastPage(pixelsScrolled: 0)

        do {
            let data = try JSONEncoder().encode(player)
            let newPlayer = try JSONDecoder().decode(WKRPlayer.self, from: data)
            XCTAssertEqual(player.raceHistory?.entries.first, newPlayer.raceHistory?.entries.first)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - WKRKitConstants

    func testConstantsBundleUpdate() {
        WKRKitConstants.removeConstants()
        WKRKitConstants.updateConstants()

        let version = WKRKitConstants.current.version
        XCTAssertEqual(WKRKitConstants.current.version, 20)

        WKRKitConstants.removeConstants()
        WKRKitConstants.updateConstants()

        XCTAssertEqual(version, WKRKitConstants.current.version)

        WKRKitConstants.removeConstants()
        WKRKitConstants.updateConstantsForTestingCharacterClipping()

        XCTAssertEqual(WKRKitConstants.current.version, 10_000)
        XCTAssertGreaterThan(WKRKitConstants.current.version, version)
    }

    // MARK: - WKRPage

    func testPageEncoding() {
        let title = "Title"
        let url = URL(string: "https://www.apple.com")!
        let page = WKRPage(title: title, url: url)

        XCTAssert(page.title == title)
        XCTAssert(page.url == url)

        testEncoding(for: page)
    }

    func testPageTitle() {
        let url = URL(string: "https://www.apple.com")!

        var title = "iPhone"
        var page = WKRPage(title: title, url: url)
        XCTAssertEqual(page.title, title)

        title = "iPhone - Wikipedia"
        page = WKRPage(title: title, url: url)
        XCTAssertEqual(page.title, "iPhone")

        page = WKRPage(title: nil, url: url)
        XCTAssertNil(page.title)

        // Testing removing 10 characters
        WKRKitConstants.updateConstantsForTestingCharacterClipping()

        title = "phone- Extra Characters"
        page = WKRPage(title: title, url: url)
        XCTAssertEqual(page.title, "phone- Extra ")

        title = "iPhone - Extra Characters"
        page = WKRPage(title: title, url: url)
        XCTAssertEqual(page.title, "iPhone - Extra ")
    }

    // MARK: - WKRHistoryEntry

    func testHistoryEntry() {
        let page = WKRPage.mockApple()

        let entryNoDuration = WKRHistoryEntry(page: page, linkHere: false)
        var entryWithDuration = WKRHistoryEntry(page: page, linkHere: true, duration: 5)

        var decoded = testEncoding(for: entryNoDuration)
        XCTAssertFalse(decoded.linkHere)

        decoded = testEncoding(for: entryWithDuration)
        XCTAssertTrue(decoded.linkHere)

        XCTAssertEqual(5, entryWithDuration.duration)
        entryWithDuration.duration = 20
        XCTAssertEqual(20, entryWithDuration.duration)

        let entryWithDifPage = WKRHistoryEntry(page: WKRPage.mockApple(withSuffix: "a"), linkHere: false)
        XCTAssertNotEqual(entryWithDifPage, entryNoDuration)
    }

    // MARK: - WKRVoteInfo

    func testVotingObject() {
        let page1 = WKRPage.mockApple()
        let page2 =  WKRPage.mockApple(withSuffix: "2")

        let player = WKRPlayerProfile.mock()

        var votingObject = WKRVoteInfo(pages: [page1, page2])

        var firstPageVotes = votingObject.page(for: 0)

        XCTAssertEqual(firstPageVotes?.page, page1)
        XCTAssertEqual(firstPageVotes?.votes, 0)

        votingObject.player(player, votedFor: page1)

        firstPageVotes = votingObject.page(for: 0)

        XCTAssertEqual(firstPageVotes?.page, page1)
        XCTAssertEqual(firstPageVotes?.votes, 1)

        votingObject.player(player, votedFor: page2)

        firstPageVotes = votingObject.page(for: 0)

        XCTAssertEqual(firstPageVotes?.page, page1)
        XCTAssertEqual(firstPageVotes?.votes, 0)

        let secondPageVotes = votingObject.page(for: 1)

        XCTAssertEqual(secondPageVotes?.page, page2)
        XCTAssertEqual(secondPageVotes?.votes, 1)

        testEncoding(for: votingObject)
    }

    // MARK: - WKRReadyStates

    func testReadyStates() {
        let playerA = WKRPlayer.mock(named: "A")
        let playerB = WKRPlayer.mock(named: "B")
        let playerC = WKRPlayer.mock(named: "C")
        playerA.state = .readyForNextRound
        playerB.state = .racing
        playerC.state = .racing

        let players = [
            playerA,
            playerB,
            playerC
        ]
        let readyStates = WKRReadyStates(players: players)

        XCTAssert(readyStates.isPlayerReady(playerA))
        XCTAssertFalse(readyStates.isPlayerReady(playerB))
        XCTAssertFalse(readyStates.areAllRacePlayersReady(racePlayers: players))

        playerA.state = .readyForNextRound
        playerB.state = .quit
        playerC.state = .readyForNextRound

        XCTAssert(readyStates.isPlayerReady(playerA))
        XCTAssertFalse(readyStates.isPlayerReady(playerB))
        XCTAssert(readyStates.areAllRacePlayersReady(racePlayers: players))

        playerA.state = .readyForNextRound
        playerB.state = .forcedEnd
        playerC.state = .readyForNextRound

        XCTAssert(readyStates.isPlayerReady(playerA))
        XCTAssertFalse(readyStates.isPlayerReady(playerB))
        XCTAssertFalse(readyStates.areAllRacePlayersReady(racePlayers: players))

        playerA.state = .readyForNextRound
        playerB.state = .readyForNextRound
        playerC.state = .readyForNextRound

        XCTAssert(readyStates.isPlayerReady(playerA))
        XCTAssert(readyStates.isPlayerReady(playerB))
        XCTAssert(readyStates.areAllRacePlayersReady(racePlayers: players))

        playerA.state = .readyForNextRound
        playerB.state = .readyForNextRound
        playerC.state = .racing

        XCTAssert(readyStates.isPlayerReady(playerA))
        XCTAssertFalse(readyStates.isPlayerReady(playerC))
        XCTAssert(readyStates.areAllRacePlayersReady(racePlayers: [playerA, playerB]))

        let playerACopy = WKRPlayer(profile: playerA.profile, isHost: false)
        let playerBCopy = WKRPlayer(profile: playerB.profile, isHost: false)
        let playerCCopy = WKRPlayer(profile: playerC.profile, isHost: false)

        playerA.state = .racing
        playerB.state = .racing
        playerC.state = .racing
        playerACopy.state = .readyForNextRound
        playerBCopy.state = .readyForNextRound
        playerCCopy.state = .readyForNextRound

        XCTAssertFalse(readyStates.isPlayerReady(playerCCopy))
        XCTAssertFalse(readyStates.areAllRacePlayersReady(racePlayers: [
            playerACopy,
            playerBCopy,
            playerCCopy]))

        playerC.state = .readyForNextRound
        XCTAssert(readyStates.isPlayerReady(playerCCopy))
        XCTAssertFalse(readyStates.areAllRacePlayersReady(racePlayers: [
            playerACopy,
            playerBCopy,
            playerCCopy]))

        playerA.state = .quit
        playerB.state = .readyForNextRound
        XCTAssertFalse(readyStates.isPlayerReady(playerACopy))
        XCTAssert(readyStates.isPlayerReady(playerBCopy))
        XCTAssert(readyStates.areAllRacePlayersReady(racePlayers: [
            playerACopy,
            playerBCopy,
            playerCCopy]))

    }

    // MARK: - WKRPlayerRaceStats

    func testPlayerRaceStats() {
        let starting = WKRPage.mockApple(withSuffix: "1")
        let playerOne = WKRPlayer.mock(named: "Andrew")
        playerOne.startedNewRace(on: starting)

        var stats = WKRPlayerRaceStats(player: playerOne)
        XCTAssertEqual(stats.raw.count, 2)
        XCTAssertEqual(stats.raw[0].value, "-")
        XCTAssertEqual(stats.raw[1].value, "0 Pixels")

        sleep(1)

        playerOne.finishedViewingLastPage(pixelsScrolled: 5)
        stats = WKRPlayerRaceStats(player: playerOne)
        XCTAssertEqual(stats.raw[0].value, "1 S")
        XCTAssertEqual(stats.raw[1].value, "5 Pixels")
    }

}
