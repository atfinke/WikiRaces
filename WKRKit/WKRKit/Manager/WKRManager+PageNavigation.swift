//
//  WKRManager+PageNavigation.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
extension WKRManager: WKRPageNavigationDelegate {

    func navigation(_ navigation: WKRPageNavigation, startedLoading url: URL) {
        _debugLog(url)
        localPlayer.finishedViewingLastPage()
        peerNetwork.send(object: WKRCodable(localPlayer))
        webView.startedPageLoad()
    }

    func navigation(_ navigation: WKRPageNavigation, failedLoading error: Error) {
        _debugLog(error)
        webView.completedPageLoad()
    }

    func navigation(_ navigation: WKRPageNavigation, loadedPage page: WKRPage) {
        _debugLog(page)

        var linkHere = false

        if let attributes = game.activeRace?.attributesFor(page) {
            _debugLog(attributes)
            if attributes.foundPage {
                localPlayer.state = .foundPage
                transitionGameState(to: .results)
                peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.foundPage))
            } else if attributes.linkOnPage {
                linkHere = true
                peerNetwork.send(object: WKRCodable(enum: WKRPlayerMessage.linkOnPage))
            }
        }

        localPlayer.viewed(page: page, linkHere: linkHere)
        peerNetwork.send(object: WKRCodable(localPlayer))

        webView.completedPageLoad()
    }

    func navigation(_ navigation: WKRPageNavigation, blockedURL url: URL) {
        _debugLog(url)
        enqueue(message: "Link not allowed", duration: 1.0)
    }

}
