//
//  WKRSoloNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 2/9/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Foundation

final internal class WKRSoloNetwork: WKRPeerNetwork {

    // MARK: - Closures

    var networkUpdate: ((WKRPeerNetworkUpdate) -> Void)?

    // MARK: - Types

    let playerProfile: WKRPlayerProfile

    // MARK: - Initialization

    init(profile: WKRPlayerProfile) {
        playerProfile = profile
    }

    // MARK: - WKRNetwork

    func send(object: WKRCodable) {
        networkUpdate?(.object(object, profile: playerProfile))
    }

    func disconnect() {
    }

}
