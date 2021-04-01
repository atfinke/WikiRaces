//
//  NearbyBrowser.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import MultipeerConnectivity

class NearbyRaceListener: NSObject, MCNearbyServiceAdvertiserDelegate {

    // MARK: - Properties -

    private lazy var peerID = MCPeerID(displayName: UUID().uuidString)
    private var advertiser: MCNearbyServiceAdvertiser?
    private var handler: ((_ hostName: String, _ raceCode: String) -> Void)?

    // MARK: - Helpers -

    func start(nearbyRaces: @escaping ((_ hostName: String, _ raceCode: String) -> Void)) {
        self.handler = nearbyRaces

        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: Nearby.serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
    }

    // MARK: - MCNearbyServiceAdvertiserDelegate -

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        if let data = context, let invite = try? JSONDecoder().decode(Nearby.Invite.self, from: data) {
            handler?(invite.hostName, invite.raceCode)
        }
        invitationHandler(false, nil)
    }
}
