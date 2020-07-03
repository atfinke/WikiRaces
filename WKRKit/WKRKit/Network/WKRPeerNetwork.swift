//
//  WKRPeerNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WKRUIKit

internal protocol WKRPeerNetwork: class {
    var networkUpdate: ((WKRPeerNetworkUpdate) -> Void)? { get set }

    func disconnect()
    func send(object: WKRCodable)
}

enum WKRPeerNetworkUpdate {
    case object(_ object: WKRCodable, profile: WKRPlayerProfile)
    case playerConnected(profile: WKRPlayerProfile)
    case playerDisconnected(profile: WKRPlayerProfile)
}
