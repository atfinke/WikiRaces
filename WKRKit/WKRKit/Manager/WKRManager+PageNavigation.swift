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
        return WKRPageNavigation(pageURLBlocked: {
            self.enqueue(message: "Link not allowed", duration: 1.0)
        }, pageLoadingError: {
            self.enqueue(message: "Error loading page", duration: 5.0)
            self.webView.completedPageLoad()
        }, pageStartedLoading: {
            self.localPlayer.finishedViewingLastPage()
            self.peerNetwork.send(object: WKRCodable(self.localPlayer))
            self.webView.startedPageLoad()
        }, pageLoaded: { page in
            self.webView.completedPageLoad()

            var linkHere = false
            var foundPage = false

            if let attributes = self.game.activeRace?.attributesFor(page) {
                if attributes.foundPage {
                    foundPage = true
                    self.peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.foundPage))
                } else if attributes.linkOnPage {
                    linkHere = true
                    self.peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.linkOnPage))
                }
            }

            self.localPlayer.nowViewing(page: page, linkHere: linkHere)

            if foundPage {
                self.localPlayer.state = .foundPage
                self.transitionGameState(to: .results)
                self.peerNetwork.send(object: WKRCodable(self.localPlayer))
            }
        })
    }

}
