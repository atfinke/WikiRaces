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
        return WKRPageNavigation(pageURLBlocked: { [weak self] url in
            self?.enqueue(message: "Link not allowed",
                          duration: 2.0,
                          isRaceSpecific: true,
                          playHaptic: true)

            self?.logEvent(WKRLogEvent(type: .pageBlocked,
                                       attributes: [
                                        "PageURL": self?.truncated(url: url) as Any
                ]))
        }, pageLoadingError: { [weak self] in
            self?.enqueue(message: "Error loading page",
                duration: 3.0,
                isRaceSpecific: true,
                playHaptic: true)

            self?.webView.completedPageLoad()
            self?.logEvent(WKRLogEvent(type: .pageLoadingError, attributes: nil))
        }, pageStartedLoading: { [weak self] in
            guard let self = self else { return }
            self.webView.startedPageLoad()
            self.localPlayer.finishedViewingLastPage(pointsScrolled: self.webView.pointsScrolled)
            self.peerNetwork.send(object: WKRCodable(self.localPlayer))
            self.linkCountUpdate(self.localPlayer.raceHistory?.entries.count ?? 0)
        }, pageLoaded: { [weak self] page in
            guard let self = self else { return }
            self.webView.completedPageLoad()

            var linkHere = false
            var foundPage = false

            if page.title == "United States" {
                self.peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.onUSA))
            }

            let lastPageHadLink = self.localPlayer.raceHistory?.entries.last?.linkHere ?? false
            if let attributes = self.game.activeRace?.attributes(for: page) {
                if attributes.foundPage {
                    foundPage = true
                    self.peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.foundPage))
                    if let time = self.localPlayer.raceHistory?.duration {
                        self.logEvent(WKRLogEvent(type: .foundPage, attributes: ["Time": time]))
                    }
                } else if attributes.linkOnPage {
                    linkHere = true
                    if !lastPageHadLink {
                        self.peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.linkOnPage))
                        self.logEvent(WKRLogEvent(type: .linkOnPage, attributes: nil))
                    }
                } else if lastPageHadLink {
                    self.peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.missedLink))
                    self.logEvent(WKRLogEvent(type: .missedLink, attributes: nil))
                }
            }

            self.localPlayer.nowViewing(page: page, linkHere: linkHere)

            if foundPage {
                self.localPlayer.state = .foundPage
                self.transitionGameState(to: .results)
            }

            self.peerNetwork.send(object: WKRCodable(self.localPlayer))
            self.logEvent(WKRLogEvent(type: .pageView, attributes: ["Page": page.title as Any]))
        })
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
