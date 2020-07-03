//
//  WKRPeerNetworkConfig.swift
//  WKRKit
//
//  Created by Andrew Finke on 2/10/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import GameKit
import WKRUIKit

public enum WKRPeerNetworkConfig {

    case solo(name: String)
    case gameKitPublic(match: GKMatch, isHost: Bool)
    case gameKitPrivate(match: GKMatch, isHost: Bool)
    case multiwindow(windowName: String, isHost: Bool)

    public var isHost: Bool {
        switch self {
        case .solo:
            return true
        case .gameKitPublic(_, let isHost), .gameKitPrivate(_, let isHost), .multiwindow(_, let isHost):
            return isHost
        }
    }

    func create() -> (player: WKRPlayer, network: WKRPeerNetwork) {
        switch self {
        case .solo(let name):
            let profile = WKRPlayerProfile(name: name, playerID: name)
            let player = WKRPlayer(profile: profile, isHost: true)
            return (player, WKRSoloNetwork(profile: profile))
        case .gameKitPublic(let match, let isHost), .gameKitPrivate(let match, let isHost):
            let player = WKRPlayer(profile: GKLocalPlayer.local.wkrProfile(), isHost: isHost)
            return (player, WKRGameKitNetwork(match: match))
        case .multiwindow(let windowName, let isHost):
            let profile = WKRPlayerProfile(name: windowName, playerID: windowName)
            let player = WKRPlayer(profile: profile, isHost: isHost)
            return(player, WKRSplitViewNetwork(playerName: windowName, isHost: isHost))
        }
    }

}
