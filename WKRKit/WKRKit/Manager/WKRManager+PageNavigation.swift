//
//  WKRManager+PageNavigation.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

extension WKRManager {

    func newPageNavigation() -> WKRPageNavigation {
        return WKRPageNavigation(pageURLBlocked: { [weak self] in
            self?.enqueue(message: "Link not allowed", duration: 1.0)
        }, pageLoadingError: { [weak self] in
            self?.enqueue(message: "Error loading page", duration: 5.0)
            self?.webView.completedPageLoad()
        }, pageStartedLoading: { [weak self] in
            self?.webView.startedPageLoad()
            if let player = self?.localPlayer {
                player.finishedViewingLastPage()
                self?.peerNetwork.send(object: WKRCodable(player))
            }
        }, pageLoaded: { [weak self] page in
            self?.webView.completedPageLoad()

            var linkHere = false
            var foundPage = false

            if let attributes = self?.game.activeRace?.attributesFor(page) {
                if attributes.foundPage {
                    foundPage = true
                    self?.peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.foundPage))
                } else if attributes.linkOnPage {
                    linkHere = true
                    self?.peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.linkOnPage))
                }
            }

            guard let localPlayer = self?.localPlayer else {
                return
            }

            localPlayer.nowViewing(page: page, linkHere: linkHere)

            if foundPage {
                localPlayer.state = .foundPage
                self?.transitionGameState(to: .results)
                self?.peerNetwork.send(object: WKRCodable(localPlayer))
            }
        })
    }

}
