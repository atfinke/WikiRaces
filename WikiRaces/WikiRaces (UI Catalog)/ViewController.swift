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

    // MARK: - History

//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let nav = viewController() as! UINavigationController
//
//        let controller = nav.rootViewController as! HistoryViewController
//
//        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = nav
//
//
//        let player = WKRPlayer(profile: WKRPlayerProfile(name: "andrew",
//                                                         playerID: "andrew"),
//                               isHost: true)
//
//        let page = WKRPage(title: "Apple Inc.", url: URL(string: "apple.com")!)
//                    player.raceHistory = WKRHistory(firstPage: page)
//
//        func random() {
//            WKRPageFetcher.fetchRandom { (page) in
//                guard let page = page else { return }
//                player.raceHistory?.finishedViewingLastPage()
//                player.nowViewing(page: page, linkHere: arc4random() % 5 == 0)
//                DispatchQueue.main.async {
//
//                    if arc4random() % 20 == 0 {
//                        player.state = .foundPage
//                    } else if arc4random() % 25 == 0 {
//                        player.state = .forfeited
//                    } else if arc4random() % 30 == 0 {
//                        player.state = .quit
//                    }
//
//                    print("Updating------")
//                    controller.player = player
//                }
//            }
//
//           // let time: CGFloat = CGFloat(arc4random() % 40) / 10.0
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                if arc4random() % 3 == 0 {
//                    //  controller.state = .points
//                    random()
//                } else {
//                    random()
//                }
//            }
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            random()
//            //            playerOneHistory.finishedViewingLastPage()
//            //            playerOneHistory.append(playerOnePageTwo, linkHere: false)
//            //            playerOne.raceHistory = playerOneHistory
//            //
//            //            playerTwoHistory.finishedViewingLastPage()
//            //            playerTwoHistory.append(playerOnePageOne, linkHere: true)
//            //            playerTwo.raceHistory = playerTwoHistory
//            //            playerTwo.state = .foundPage
//            //
//            //            controller.resultsInfo = WKRResultsInfo(players: [playerOne, playerTwo], racePoints: [:], sessionPoints: [:])
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                }
//            }
//        }
//
//    }
//
//    func viewController() -> UIViewController {
//        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HistoryNav")
//    }

    // MARK: - ResultsViewController Testing

    var players = [WKRPlayer]()
    let res = ResultRenderer()

    var rendered = false

    override func viewDidLoad() {
        super.viewDidLoad()

        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = GKSplashViewController()
      //  return
        let nav = viewController() as! UINavigationController

        let controller = nav.rootViewController as! ResultsViewController

        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = nav

        //let names = ["Andrew", "Carol", "Tom", "Lisa", "Midnight", "Uncle D", "Pops", "Sam"]
        let names = ["Andrew", "Carol", "Tom", "Lisa"]

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
            for player in players where player.state == .racing {
                WKRPageFetcher.fetchRandom { (page) in
                    guard let page = page else { return }
                    DispatchQueue.main.async {

                        if player.state == .racing {
                            if arc4random() % 20 == 0, player.raceHistory?.entries.count ?? 0 > 2 {
                                player.state = .foundPage
                            } else if arc4random() % 25 == 0 {
                                player.state = .forcedEnd
                            } else if arc4random() % 30 == 0 {
                                player.state = .quit
                            } else if arc4random() % 30 == 0 {
                                player.state = .forfeited
                            } else {
                                player.raceHistory?.finishedViewingLastPage()
                                player.nowViewing(page: page, linkHere: arc4random() % 5 == 0)
                            }

                        }

                        //                        controller.player = self.players[0]
                        controller.resultsInfo = WKRResultsInfo(players: self.players,
                                                                racePoints: [:],
                                                                sessionPoints: [:])

                        controller.showReadyUpButton(true)

                    }

                }
            }

            // let time: CGFloat = CGFloat(arc4random() % 40) / 10.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if arc4random() % 3 == 0 {
                    //  controller.state = .points
                    random()
                } else {
                    random()
                }

                if self.players.filter ({$0.state == .racing }).isEmpty && !self.rendered {
                    self.rendered = true
                    for player in self.players {
                        ResultRenderer().render(with: controller.resultsInfo!, for: player, on: controller.contentView, completion: { _ in
                        })
                    }
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
        }

    }

    func viewController() -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultsNav")
    }

}
