//
//  WKRGameManager+PageNavigation.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

extension WKRGameManager {

    func newPageNavigation() -> WKRPageNavigation {
        func displayNetworkAlert(title: String, duration: Double) {
            guard gameState != .results ||
                gameState != .hostResults ||
                gameState != .points else  {
                    return
            }
            enqueue(message: title,
                    duration: duration,
                    isRaceSpecific: true,
                    playHaptic: true)
        }

        return WKRPageNavigation(pageUpdate: { [weak self] pageUpdate in
            guard let self = self else { return }
            switch pageUpdate {
            case .urlBlocked(let url):
                displayNetworkAlert(title: "Link not allowed", duration: 2)
                self.gameUpdate(.log(WKRLogEvent(type: .pageBlocked,
                                                 attributes: [
                                                    "PageURL": self.truncated(url: url) as Any
                    ])))
            case .loadingError(_):
                displayNetworkAlert(title: "Error loading page", duration: 3)

                self.webView.completedPageLoad()
                self.gameUpdate(.log(WKRLogEvent(type: .pageLoadingError, attributes: nil)))

                // use a bit of an extra timeout to give player chance to reconnect
                WKRConnectionTester.start(timeout: WKRKitConstants.current.connectionTestTimeout * 3,
                                          completionHandler: { success in
                    if !success {
                        self.localErrorOccurred(.internetSpeed)
                    }
                })
            case .startedLoading:
                self.webView.startedPageLoad()
                self.localPlayer.finishedViewingLastPage(pointsScrolled: self.webView.pointsScrolled)
                self.peerNetwork.send(object: WKRCodable(self.localPlayer))

                let linkCount = self.localPlayer.raceHistory?.entries.count ?? 0
                self.gameUpdate(.playerRaceLinkCountForCurrentRace(linkCount))
            case .loaded(let page):
                self.pageLoaded(page)
            }
        })
    }

    private func pageLoaded(_ page: WKRPage) {
        webView.completedPageLoad()

        var linkHere = false
        var foundPage = false

        if page.title == "United States" {
            self.peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.onUSA))
        }

        let lastPageHadLink = localPlayer.raceHistory?.entries.last?.linkHere ?? false
        if let attributes = game.activeRace?.attributes(for: page) {
            if attributes.foundPage {
                foundPage = true
                peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.foundPage))
                if let time = localPlayer.raceHistory?.duration {
                    gameUpdate(.log(WKRLogEvent(type: .foundPage, attributes: ["Time": time])))
                }
            } else if attributes.linkOnPage {
                linkHere = true
                if !lastPageHadLink {
                    peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.linkOnPage))
                    gameUpdate(.log(WKRLogEvent(type: .linkOnPage, attributes: nil)))
                }
            } else if lastPageHadLink {
                peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.missedLink))
                gameUpdate(.log(WKRLogEvent(type: .missedLink, attributes: nil)))
            }
        }

        localPlayer.nowViewing(page: page, linkHere: linkHere)

        if foundPage {
            localPlayer.state = .foundPage
            transitionGameState(to: .results)
        }

        peerNetwork.send(object: WKRCodable(localPlayer))
        gameUpdate(.log(WKRLogEvent(type: .pageView, attributes: ["Page": page.title as Any])))
    }

    private func truncated(url: URL) -> String {
        var reportedURLString = url.absoluteString
        if reportedURLString.starts(with: "https://en.m.wikipedia.org/wiki/") {
            let index = reportedURLString.index(reportedURLString.startIndex, offsetBy: 31)
            reportedURLString = String(reportedURLString[index...])
        }
        if reportedURLString.count > 100 {
            let index = reportedURLString.index(reportedURLString.endIndex, offsetBy: -4)
            reportedURLString = reportedURLString[...index] + "+++"
        }
        return reportedURLString
    }

}
