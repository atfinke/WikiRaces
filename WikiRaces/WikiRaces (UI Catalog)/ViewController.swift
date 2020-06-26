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
    
    // MARK: - ResultsViewController Testing
    
    var players = [WKRPlayer]()
    let res = ResultRenderer()
    
    var rendered = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        voting()
        results()
    }
    
    func voting() {
        
        let controller = VotingViewController()
        let nav = UINavigationController(rootViewController: controller)
        
        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = nav
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let appleURL = URL(string: "https://en.m.wikipedia.org/wiki/Apple_Inc."),
                  let usaURL = URL(string: "https://en.m.wikipedia.org/wiki/United_States."),
                  let waltURL = URL(string: "https://en.m.wikipedia.org/wiki/Walt_Disney") else {
                fatalError()
            }
            var state = WKRVotingState(pages: [
                WKRPage(title: "Apple Inc Apple Inc Apple Inc Apple Inc Apple Inc Apple Inc Apple Inc Apple Inc Apple Inc Apple Inc", url: appleURL),
                WKRPage(title: "United States", url: usaURL),
                WKRPage(title: "Walt Disney", url: waltURL)
            ])
            
            controller.votingState = state
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                state.player(WKRPlayerProfile(name: "", playerID: ""), votedFor: WKRPage(title: "Walt Disney", url: waltURL))
                controller.votingState = state
                controller.voteTimeRemaing = 5
            }
        }
    }
    
    func results() {
        let controller = ResultsViewController()
        let nav = UINavigationController(rootViewController: controller)
        
        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = nav
        
        //        let names = ["Andrew", "Carol", "Tom", "Lisa", "Midnight", "Uncle D", "Pops", "Sam"]
        let names = ["Andrew", "Carol", "Tom", "Lisa"]
        
        for var index in 0..<names.count {
            let profile = WKRPlayerProfile(name: names[index], playerID: names[index])
            let player = WKRPlayer(profile: profile, isHost: false)
            let page = WKRPage(title: "Apple Inc.", url: URL(string: "apple.com")!)
            player.startedNewRace(on: page)
            
            players.append(player)
        }
        var stop = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
//            stop = true
            controller.showReadyUpButton(true)
        }
        
        //
        
        func random() {
            guard !stop else { return }
            for player in players where player.state == .racing {
                WKRPageFetcher.fetchRandom { (page) in
                    guard let page = page else { return }
                    DispatchQueue.main.async {
                        
                        if player.state == .racing {
                            if arc4random() % 20 == 0, player.raceHistory?.entries.count ?? 0 > 4 {
                                player.state = .foundPage
                                //                            } else if arc4random() % 25 == 0 {
                                //                                player.state = .forcedEnd
                                //                            } else if arc4random() % 30 == 0 {
                                //                                player.state = .quit
                                //                            } else if arc4random() % 30 == 0 {
                                //                                player.state = .forfeited
                            } else {
                                player.finishedViewingLastPage(pixelsScrolled: 5)
                                player.nowViewing(page: page, linkHere: arc4random() % 5 == 0)
                            }
                            
                        }
                        guard !stop else { return }
                        //                        controller.player = self.players[0]
                        controller.resultsInfo = WKRResultsInfo(racePlayers: self.players,
                                                                racePoints: [:],
                                                                sessionPoints: [:])
                        
                       
                        
                    }
                    
                }
            }
            
            let time: DispatchTimeInterval = .seconds(Int.random(in: 1...5))
            DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                if arc4random() % 3 == 0 {
                    //  controller.state = .points
                    random()
                } else {
                    random()
                }
                
                //                if self.players.filter({$0.state == .racing }).isEmpty && !self.rendered {
                //                    self.rendered = true
                //                    for player in self.players {
                //                        ResultRenderer().render(with: controller.resultsInfo!,
                //                                                for: player,
                //                                                on: controller.contentView,
                //                                                completion: { _ in
                //                        })
                //                    }
                //                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            random()
        }
    }
    
}
