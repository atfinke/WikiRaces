//
//  WKRGameManager+PeerNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WKRUIKit

extension WKRGameManager {

    // MARK: - WKRPeerNetwort

    func configure(network: WKRPeerNetwork) {
        network.networkUpdate = { [weak self] networkUpdate in
            guard let self = self else { return }

            switch networkUpdate {
            case .object(let object, let profile):
                DispatchQueue.main.async {
                    if !self.isFailing {
                        self.receivedCodable(object, from: profile)
                    }
                }
            case .playerConnected:
                self.peerNetwork.send(object: WKRCodable(self.localPlayer))
            case .playerDisconnected(let profile):
                if profile == self.localPlayer.profile {
                    if self.gameState != .preMatch {
                        self.localErrorOccurred(.noPeers)
                    }
                } else {
                    let disconnectedPlayerIsHost = self.game.players.first(where: { player -> Bool in
                        return player.profile == profile
                    })?.isHost ?? false
                    if disconnectedPlayerIsHost {
                        self.localErrorOccurred(.disconnected)
                    }
                    self.game.playerDisconnected(profile)
                }
            }
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
