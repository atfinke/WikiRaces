//
//  WKRKitTests.swift
//  WKRKitTests
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import XCTest
@testable import WKRKit

class WKRKitTests: WKRKitTestCase {

    // MARK: - Object Tests

    func testState() {
        var state = WKRGameState.voting
        testEnumEncoding(for: state)

        state = WKRGameState.race
        testEnumEncoding(for: state)
    }

    func testHistory() {
        let startingPage = applePage(withSuffix: "1")
        let endingPage = applePage(withSuffix: "2")

        var historyOne = WKRHistory(firstPage: startingPage)
        historyOne.append(startingPage, linkHere: false)
        historyOne.append(endingPage, linkHere: false)

        var historyTwo = WKRHistory(firstPage: endingPage)
        historyTwo.append(endingPage, linkHere: false)
        historyTwo.append(startingPage, linkHere: false)

        testEncoding(for: historyOne)
        testEncoding(for: historyTwo)
    }

    func testRace() {
        /*let startingPage = applePage(withSuffix: "1")
         let endingPage = applePage(withSuffix: "2")

         var race = WKRRace(starting: startingPage, ending: endingPage)

         XCTAssert(race.startingPage == startingPage)
         XCTAssert(race.endingPage == endingPage)
         XCTAssert(race.endingPage != startingPage)

         let playerOne = WKRPlayer(name: "Andrew", playerID: "10")
         let playerTwo = WKRPlayer(name: "Midnight", playerID: "20")
         race.set(player: playerOne, state: .foundPage)
         race.set(player: playerTwo, state: .forcedEnd)

         var historyOne = WKRHistory()
         var historyTwo = WKRHistory()
         historyOne.append(startingPage)
         historyTwo.append(endingPage)

         race.set(player: playerOne, history: historyOne)
         race.set(player: playerTwo, history: historyTwo)

         testEncoding(for: race)*/
    }

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

        let page = applePage()
        player.startedNewRace(on: page)
        player.finishedViewingLastPage()

        do {
            let data = try JSONEncoder().encode(player)
            let newPlayer = try JSONDecoder().decode(WKRPlayer.self, from: data)
            XCTAssertEqual(player.raceHistory?.entries.first, newPlayer.raceHistory?.entries.first)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testPage() {
        let title = "Title"
        let url = URL(string: "https://www.apple.com")!
        let page = WKRPage(title: title, url: url)

        XCTAssert(page.title == title)
        XCTAssert(page.url == url)

        testEncoding(for: page)
    }

    func testHistoryEntry() {
        let page = applePage()
        let entryNoDuration = WKRHistoryEntry(page: page, linkHere: false)
        let entryWithDuration = WKRHistoryEntry(page: page, linkHere: false, duration: 5)

        testEncoding(for: entryNoDuration)
        testEncoding(for: entryWithDuration)
    }

    func testVotingObject() {
        let page1 = applePage()
        let page2 = applePage(withSuffix: "2")

        let player = uniqueProfile()

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

        // testEncoding(for: votingObject)
    }

}
