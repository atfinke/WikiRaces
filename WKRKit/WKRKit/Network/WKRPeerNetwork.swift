//
//  WKRPeerNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

protocol WKRPeerNetwork: class {
    var connectedPlayers: Int { get }

    var objectReceived: ((WKRCodable, WKRPlayerProfile) -> Void)? { get set }
    var playerConnected: ((WKRPlayerProfile) -> Void)? { get set }
    var playerDisconnected: ((WKRPlayerProfile) -> Void)? { get set }

    func disconnect()
    func send(object: WKRCodable)
    func presentNetworkInterface(on viewController: UIViewController)
}
