//
//  WKRManager+PeerNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
extension WKRManager: WKRPeerNetworkDelegate {

    // MARK: - WKRPeerNetworkDelegate

    func network(_ network: WKRPeerNetwork, playerConnected profile: WKRPlayerProfile) {
        _debugLog(player)
        peerNetwork.send(object: WKRCodable(localPlayer))
    }

    func network(_ network: WKRPeerNetwork, playerDisconnected profile: WKRPlayerProfile) {
        _debugLog(player)
        game.player(profile, stateUpdated: .disconnected)
    }

    func network(_ network: WKRPeerNetwork, didReceive object: WKRCodable, fromPlayer profile: WKRPlayerProfile) {
        _debugLog(profile)
        _debugLog(object)
        DispatchQueue.main.async {
            self.receivedCodable(object, from: profile)
        }
    }

    // MARK: - Object Handling

    func receivedCodable(_ object: WKRCodable, from player: WKRPlayerProfile) {
        switch object.key {
        case .raw:
            receivedRaw(object, from: player)
        case .int:
            receivedInt(object, from: player)
        case .enumCodable:
            receivedEnum(object, from: player)
        }
    }

}
