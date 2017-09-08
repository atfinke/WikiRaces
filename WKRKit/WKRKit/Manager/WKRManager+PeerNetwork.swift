//
//  WKRManager+PeerNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

extension WKRManager {

    // MARK: - WKRPeerNetwort

    func configure(network: WKRPeerNetwork) {
        network.objectReceived = { [weak self]object, profile in
            DispatchQueue.main.async {
                self?.receivedCodable(object, from: profile)
            }
        }
        network.playerConnected = { [weak self] profile in
            if let player = self?.localPlayer {
                self?.peerNetwork.send(object: WKRCodable(player))
            }
        }
        network.playerDisconnected = { [weak self] profile in
            self?.game.playerDisconnected(profile)
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
