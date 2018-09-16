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
            self?.enqueue(message: "Link not allowed", duration: 1.0)
            self?.logEvent("pageBlocked", ["PageURL": self?.truncated(url: url) as Any])
        }, pageLoadingError: { [weak self] in
            self?.enqueue(message: "Error loading page", duration: 5.0)
            self?.webView.completedPageLoad()
        }, pageStartedLoading: { [weak self] in
            self?.webView.startedPageLoad()
            if let player = self?.localPlayer {
                player.finishedViewingLastPage()
                self?.peerNetwork.send(object: WKRCodable(player))
            }
            self?.linkCountUpdate(self?.localPlayer.raceHistory?.entries.count ?? 0)
        }, pageLoaded: { [weak self] page in
            self?.webView.completedPageLoad()

            var linkHere = false
            var foundPage = false

            let lastPageHadLink = self?.localPlayer.raceHistory?.entries.last?.linkHere ?? false
            if let attributes = self?.game.activeRace?.attributesFor(page) {
                if attributes.foundPage {
                    foundPage = true
                    self?.peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.foundPage))
                } else if attributes.linkOnPage {
                    linkHere = true
                    if !lastPageHadLink {
                        self?.peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.linkOnPage))
                    }
                } else if lastPageHadLink {
                    self?.peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.missedLink))
                }
            }

            guard let localPlayer = self?.localPlayer else {
                return
            }

            localPlayer.nowViewing(page: page, linkHere: linkHere)

            if foundPage {
                localPlayer.state = .foundPage
                self?.transitionGameState(to: .results)
            }

            self?.peerNetwork.send(object: WKRCodable(localPlayer))
            self?.logEvent("pageView", ["Page": page.title as Any])
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
