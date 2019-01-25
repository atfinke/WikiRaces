//
//  WKRSoloNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 2/9/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation

internal class WKRSoloNetwork: WKRPeerNetwork {

    // MARK: - Closures

    var objectReceived: ((WKRCodable, WKRPlayerProfile) -> Void)?
    var playerConnected: ((WKRPlayerProfile) -> Void)?
    var playerDisconnected: ((WKRPlayerProfile) -> Void)?

    // MARK: - Types

    let playerProfile: WKRPlayerProfile

    // MARK: - Initialization

    init(profile: WKRPlayerProfile) {
        playerProfile = profile
    }

    // MARK: - WKRNetwork

    func send(object: WKRCodable) {
        objectReceived?(object, playerProfile)
    }

    func disconnect() {
    }

    func hostNetworkInterface() -> UIViewController? {
        return nil
    }

}

// MARK: - WKRKit Extensions

extension WKRGameManager {

    internal convenience init(soloPlayerName: String,
                              stateUpdate: @escaping ((WKRGameState, WKRFatalError?) -> Void),
                              pointsUpdate: @escaping ((Int) -> Void),
                              linkCountUpdate: @escaping ((Int) -> Void),
                              logEvent: @escaping ((String, [String: Any]?) -> Void)) {

        let profile = WKRPlayerProfile(name: soloPlayerName, playerID: soloPlayerName)
        let player = WKRPlayer(profile: profile, isHost: true)
        let network = WKRSoloNetwork(profile: profile)

        self.init(player: player,
                  network: network,
                  stateUpdate: stateUpdate,
                  pointsUpdate: pointsUpdate,
                  linkCountUpdate: linkCountUpdate,
                  logEvent: logEvent)
    }

}
