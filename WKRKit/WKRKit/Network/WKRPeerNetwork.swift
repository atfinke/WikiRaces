//
//  WKRPeerNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

protocol WKRPeerNetworkDelegate: class {
    func network(_ network: WKRPeerNetwork, playerConnected profile: WKRPlayerProfile)
    func network(_ network: WKRPeerNetwork, playerDisconnected profile: WKRPlayerProfile)
    func network(_ network: WKRPeerNetwork, didReceive object: WKRCodable, fromPlayer profile: WKRPlayerProfile)
}

protocol WKRPeerNetwork: class {
    var isHost: Bool { get }
    var connectedPlayers: Int { get }

    weak var delegate: WKRPeerNetworkDelegate? { get set }

    func disconnect()
    func send(object: WKRCodable)
    func presentNetworkInterface(on viewController: UIViewController)
}
