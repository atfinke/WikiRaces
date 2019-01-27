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
