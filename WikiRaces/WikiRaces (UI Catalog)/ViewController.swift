//
//  ViewController.swift
//  WikiRaces (UI Catalog)
//
//  Created by Andrew Finke on 9/17/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

@testable import WKRKit
@testable import WKRUIKit

internal class ViewController: UIViewController {

    //swiftlint:disable line_length force_cast

    var players = [WKRPlayer]()

    override func viewDidLoad() {
        super.viewDidLoad()

        let nav = viewController() as! UINavigationController

        let controller = nav.rootViewController as! ResultsViewController

        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = nav

        let names = ["Andrew", "Carol", "Tom", "Lisa", "Midnight", "Uncle D", "Pops", "Sam"]
        for var index in 0..<names.count {
            let profile = WKRPlayerProfile(name: names[index], playerID: names[index])
            let player = WKRPlayer(profile: profile, isHost: false)
            player.state = .racing

            let page = WKRPage(title: "Apple Inc.", url: URL(string: "apple.com")!)
            player.raceHistory = WKRHistory(firstPage: page)

            players.append(player)
        }

        //

        func random() {

            //            players[1].state = .forcedEnd
            //
            //            controller.resultsInfo = WKRResultsInfo(players: self.players,
            //                                                    racePoints: [:],
            //                                                    sessionPoints: [:])

            for player in players where player.state == .racing {
                WKRPageFetcher.fetchRandom { (page) in
                    guard let page = page else { return }
                    player.raceHistory?.finishedViewingLastPage()
                    player.nowViewing(page: page, linkHere: arc4random() % 5 == 0)
                    DispatchQueue.main.async {

                                                if arc4random() % 20 == 0 {
                                                    player.state = .foundPage
                                                } else if arc4random() % 25 == 0 {
                                                    player.state = .forfeited
                                                } else if arc4random() % 30 == 0 {
                                                    player.state = .quit
                                                }

                        //                        controller.player = self.players[0]
                        controller.resultsInfo = WKRResultsInfo(players: self.players,
                                                                racePoints: [:],
                                                                sessionPoints: [:])
                        print("Updating------")
                    }

                }
            }

           // let time: CGFloat = CGFloat(arc4random() % 40) / 10.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if arc4random() % 3 == 0 {
                    //  controller.state = .points
                    random()
                } else {
                    random()
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            random()
            //            playerOneHistory.finishedViewingLastPage()
            //            playerOneHistory.append(playerOnePageTwo, linkHere: false)
            //            playerOne.raceHistory = playerOneHistory
            //
            //            playerTwoHistory.finishedViewingLastPage()
            //            playerTwoHistory.append(playerOnePageOne, linkHere: true)
            //            playerTwo.raceHistory = playerTwoHistory
            //            playerTwo.state = .foundPage
            //
            //            controller.resultsInfo = WKRResultsInfo(players: [playerOne, playerTwo], racePoints: [:], sessionPoints: [:])

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                }
            }
        }

    }

    func viewController() -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultsNav")
    }

}
