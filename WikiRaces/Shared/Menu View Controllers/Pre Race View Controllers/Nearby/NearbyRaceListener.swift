//
//  NearbyRaceListener.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/23/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import GameKit
import MultipeerConnectivity
import os.log

class NearbyRaceListener: NSObject, MCNearbyServiceAdvertiserDelegate {

    // MARK: - Properties -

    private var advertiser: MCNearbyServiceAdvertiser?
    private var handler: ((_ hostName: String, _ raceCode: String) -> Void)?

    // MARK: - Helpers -

    func start(nearbyRaces: @escaping ((_ hostName: String, _ raceCode: String) -> Void)) {
        os_log("Listener: %{public}s", log: .nearby, type: .info, #function)
        self.handler = nearbyRaces

        advertiser = MCNearbyServiceAdvertiser(peer: Nearby.peerID, discoveryInfo: nil, serviceType: Nearby.serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    func stop() {
        os_log("Listener: %{public}s", log: .nearby, type: .info, #function)
        advertiser?.stopAdvertisingPeer()
    }

    // MARK: - MCNearbyServiceAdvertiserDelegate -

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        defer {
            invitationHandler(false, nil)
        }
        
        guard let data = context, let invite = try? JSONDecoder().decode(Nearby.Invite.self, from: data) else {
            return
        }
        
        if GKHelper.shared.isAuthenticated && invite.hostName == GKLocalPlayer.local.alias {
            os_log("Listener: same name, skipping", log: .nearby, type: .info, #function)
            return
        }
        
        os_log("Listener: %{public}s: host name: %{public}s, race code: %{public}s", log: .nearby, type: .info, #function, invite.hostName, invite.raceCode)
        handler?(invite.hostName, invite.raceCode)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        os_log("Listener: %{public}s: %{public}s", log: .nearby, type: .info, #function, error.localizedDescription)
    }
    
}
