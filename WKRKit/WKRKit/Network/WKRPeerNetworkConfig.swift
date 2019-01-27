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

public enum WKRPeerNetworkConfig {

    case solo(name: String)
    case gameKit(match: GKMatch, isHost: Bool)
    case multiwindow(windowName: String, isHost: Bool)
    case mpc(serviceType: String, session: MCSession, isHost: Bool)

    public var isHost: Bool {
        switch self {
        case .solo:
            return true
        case .gameKit(_, let isHost):
            return isHost
        case .mpc(_, _, let isHost):
            return isHost
        case .multiwindow(_, let isHost):
            return isHost
        }
    }

    func create() -> (player: WKRPlayer, network: WKRPeerNetwork) {
        switch self {
        case .solo(let name):
            let profile = WKRPlayerProfile(name: name, playerID: name)
            let player = WKRPlayer(profile: profile, isHost: true)
            return (player, WKRSoloNetwork(profile: profile))
        case .gameKit(let match, let isHost):
            let player = WKRPlayer(profile: GKLocalPlayer.local.wkrProfile(), isHost: isHost)
            return (player, WKRGameKitNetwork(match: match))
        case .mpc(let serviceType, let session, let isHost):
            let player = WKRPlayer(profile: session.myPeerID.wkrProfile(), isHost: isHost)
            return (player, WKRMultipeerNetwork(serviceType: serviceType, session: session))
        case .multiwindow(let windowName, let isHost):
            let profile = WKRPlayerProfile(name: windowName, playerID: windowName)
            let player = WKRPlayer(profile: profile, isHost: isHost)
            return(player, WKRSplitViewNetwork(playerName: windowName, isHost: isHost))
        }
    }

}
