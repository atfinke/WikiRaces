//
//  WKRGameKitNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 1/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Foundation
import GameKit

final internal class WKRGameKitNetwork: NSObject, GKMatchDelegate, WKRPeerNetwork {

    // MARK: - Closures

    var networkUpdate: ((WKRPeerNetworkUpdate) -> Void)?

    // MARK: - Properties

    private weak var match: GKMatch?

    // MARK: - Initialization

    init(match: GKMatch) {
        self.match = match
        super.init()
        match.delegate = self
    }

    // MARK: - WKRNetwork

    func disconnect() {
        match?.disconnect()
    }

    func send(object: WKRCodable) {
        guard let match = match, let data = try? WKRCodable.encoder.encode(object) else { return }
        do {
            try match.sendData(toAllPlayers: data, with: .reliable)
            networkUpdate?(.object(object, profile: GKLocalPlayer.local.wkrProfile()))
        } catch {
            print(error)
        }
    }

    // MARK: - MCSessionDelegate

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        do {
            let object = try WKRCodable.decoder.decode(WKRCodable.self, from: data)
            networkUpdate?(.object(object, profile: player.wkrProfile()))
        } catch {
            print(data.description)
        }
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected: self.networkUpdate?(.playerConnected(profile: player.wkrProfile()))
            case .disconnected: self.networkUpdate?(.playerDisconnected(profile: player.wkrProfile()))
            default: break
            }

            // no players left
            if match.players.isEmpty {
                self.networkUpdate?(.playerDisconnected(profile: GKLocalPlayer.local.wkrProfile()))
            }
        }
    }

}

// MARK: - WKRKit Extensions

extension GKPlayer {
    func wkrProfile() -> WKRPlayerProfile {
        // alias is unique, but teamPlayerID is different depending on local or remote player
        return WKRPlayerProfile(name: displayName, playerID: alias)
    }
}

extension WKRPlayer {
    static var isLocalPlayerCreator: Bool {
        return GKLocalPlayer.local.isAuthenticated && GKLocalPlayer.local.alias == "J3D1 WARR10R"
    }
}
